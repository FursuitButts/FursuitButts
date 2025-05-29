# frozen_string_literal: true

class PostReplacement < ApplicationRecord
  class ProcessingError < StandardError; end

  TAGS_TO_REMOVE_AFTER_ACCEPT = %w[better_version_at_source].freeze
  HIGHLIGHTED_TAGS = %w[better_version_at_source avoid_posting conditional_dnp].freeze
  has_media_asset(:post_replacement_media_asset)

  belongs_to(:post)
  belongs_to_creator
  belongs_to(:approver, class_name: "User", optional: true)
  belongs_to(:rejector, class_name: "User", optional: true)
  belongs_to(:uploader_on_approve, class_name: "User", foreign_key: :uploader_id_on_approve, optional: true)
  attr_accessor(:file, :direct_url, :tags, :is_backup, :as_pending)

  validate(:user_is_not_limited, on: :create)
  validate(:post_is_valid, on: :create)
  validate(:set_file_name, on: :create, if: :is_direct?)
  validate(:direct_url_is_whitelisted, on: :create)
  validates(:reason, length: { minimum: 5, maximum: 150 }, presence: true, on: :create)
  validates(:rejection_reason, length: { maximum: 150 }, if: :rejected?)
  validate(:validate_media_asset_status, on: :create)

  after_create(-> { post.update_index })
  before_destroy(:log_destroy)
  after_destroy(-> { post.update_index })
  after_commit(:delete_files, on: :destroy)

  scope(:for_user, ->(id) { where(creator_id: id.to_i) })
  scope(:for_uploader_on_approve, ->(id) { where(uploader_id_on_approve: id.to_i) })
  scope(:penalized, -> { where(penalize_uploader_on_approve: true) })
  scope(:not_penalized, -> { where(penalize_uploader_on_approve: false) })

  enum(:status, %w[uploading pending original rejected approved promoted].index_with(&:to_s))
  delegate(:storage_id, to: :media_asset)

  def delete_files
    media_asset&.expunge!
  end

  def validate_media_asset_status
    status = media_asset.status
    status_message = media_asset.pretty_status
    return unless %w[duplicate failed expunged].include?(status)
    errors.add(:base, status_message)
  end

  def direct_url_parsed
    return nil unless direct_url =~ %r{\Ahttps?://}i
    begin
      Addressable::URI.heuristic_parse(direct_url)
    rescue Addressable::URI::InvalidURIError
      nil
    end
  end

  def direct_url_is_whitelisted
    return true if direct_url_parsed.blank?
    valid, reason = UploadWhitelist.is_whitelisted?(direct_url_parsed)
    unless valid
      errors.add(:source, "is not whitelisted: #{reason}")
      return false
    end
    true
  end

  module PostMethods
    def post_is_valid
      if post.is_deleted?
        errors.add(:post, "is deleted")
        false
      end
    end
  end

  def user_is_not_limited
    return true if original?
    uploadable = creator.can_upload_with_reason
    if uploadable != true
      errors.add(:creator, User.upload_reason_string(uploadable))
      throw(:abort)
    end

    # Janitor bypass replacement limits
    return true if creator.is_janitor?

    if post.replacements.where(creator_id: creator.id).where("created_at > ?", 1.day.ago).count > FemboyFans.config.post_replacement_per_day_limit
      errors.add(:creator, "has already suggested too many replacements for this post today")
      throw(:abort)
    end
    if post.replacements.pending.where(creator_id: creator.id).count > FemboyFans.config.post_replacement_per_post_limit
      errors.add(:creator, "already has too many pending replacements for this post")
      throw(:abort)
    end
    true
  end

  def source_list
    source.split("\n").uniq.compact_blank
  end

  def log_destroy
    PostEvent.add!(post_id, CurrentUser.user, :replacement_deleted, post_replacement_id: id, md5: md5, storage_id: storage_id)
  end

  module StorageMethods
    def set_file_name
      if file.present?
        self.file_name = file.try(:original_filename) || File.basename(file.path)
      else
        if direct_url_parsed.blank? && direct_url.present?
          errors.add(:direct_url, "is invalid")
          throw(:abort)
        end
        if direct_url_parsed.blank?
          errors.add(:base, "No file or replacement URL provided")
          throw(:abort)
        end
        self.file_name = direct_url_parsed.basename
      end
    end

    def replacement_file_path
      media_asset.file_path
    end

    def replacement_thumb_path
      media_asset.find_variant!("thumb").file_path
    end

    def replacement_file_url
      media_asset.file_url
    end

    def replacement_thumb_url
      media_asset.find_variant!("thumb").file_url
    end
  end

  module ProcessingMethods
    # promoting
    def create_upload(replace: false)
      existing = UploadMediaAsset.duplicates_of(md5)
      if existing.any?
        existing.each do |asset|
          raise(ProcessingError, "UploadMediaAsset with md5=#{md5} and status=active already exists (id=#{asset.id}, post_id=#{asset.post.id})") if asset.post.present?
          asset.destroy # if the upload media asset has no post, it should be abandoned and not attached to anything
        end
      end
      Upload.create(new_upload_params(replace: replace))
    end

    # approving
    def update_post_media_asset
      media_asset.open_file { |file| post.media_asset.replace_file(file, md5) }
    end

    def create_backup_replacement
      backup = nil
      begin
        post.media_asset.open_file do |file|
          backup = post.replacements.new(checksum: post.md5, creator_id: post.uploader_id, creator_ip_addr: post.uploader_ip_addr, status: "original", file_name: "#{post.md5}.#{post.file_ext}", source: post.source, reason: "Original File", is_backup: true)
          backup.media_asset.backup_post_id = post.id
          backup.media_asset.append_all!(file, save: false)
          backup.save!
        end
      rescue Exception => e
        raise(ProcessingError, "Failed to create post file backup: #{e.message}")
      end
      raise(ProcessingError, "Could not create post file backup?") unless backup.present? && backup.valid?
      raise(ProcessingError, "Failed to create post file backup: #{backup.errors.full_messages.join('; ')}") unless backup.valid?(:status)
      backup
    end

    def approve!(penalize_current_uploader:)
      unless %w[pending original rejected].include?(status)
        errors.add(:status, "must be pending, original, or rejected to approve")
        return
      end
      errors.add(:post, "is deleted") if post.is_deleted?
      transaction do # rubocop:disable Metrics/BlockLength
        create_backup_replacement if post.replacements.original.none?

        post.replacements.approved.find_each do |replacement|
          replacement.update_column(:status, replacement.sequence == 0 ? "original" : "rejected")
        end

        PostReplacement::TAGS_TO_REMOVE_AFTER_ACCEPT.each do |tag|
          post.remove_tag(tag)
        end

        previous_uploader = post.uploader_id
        previous_md5 = post.md5

        previous_media_asset = post.media_asset

        post.thumbnail_frame = nil
        post.source = "#{source}\n" + post.source
        post.uploader_id = creator_id
        post.uploader_ip_addr = creator_ip_addr
        post.approver_id = CurrentUser.id
        post.save!

        self.previous_details = {
          width:  post.image_width,
          height: post.image_height,
          size:   post.file_size,
          ext:    post.file_ext,
          md5:    post.md5,
        }
        self.approver_id = CurrentUser.id
        self.status = "approved"
        self.uploader_id_on_approve = previous_uploader
        self.penalize_uploader_on_approve = penalize_current_uploader.to_s.truthy?
        save!

        upload = create_upload(replace: true)
        raise(ProcessingError, "Failed to create upload: #{upload.errors.full_messages.join('; ')}") if upload.errors.any? || !upload.valid?
        raise(ProcessingError, "Failed to create media asset: #{upload.media_asset.errors.full_messages.join('; ')}") if upload.media_asset.errors.any? || !upload.media_asset.valid?

        post.update_column(:upload_media_asset_id, upload.upload_media_asset_id)
        post.reload_media_asset
        # update_all is used to avoid needing to load the user
        User.where(id: previous_uploader).update_all("own_post_replaced_count = own_post_replaced_count + 1")
        if penalize_current_uploader
          User.where(id: previous_uploader).update_all("own_post_replaced_penalize_count = own_post_replaced_penalize_count + 1")
        end

        x_scale = post.media_asset.image_width.to_f / previous_media_asset.image_width.to_f
        y_scale = post.media_asset.image_height.to_f / previous_media_asset.image_height.to_f

        post.notes.each do |note|
          note.rescale!(x_scale, y_scale) # save! is called within each, and each loads the post
        end

        if post.md5 != previous_md5
          previous_media_asset.delete_all_files
          previous_media_asset.replaced!
        end

        PostEvent.add!(post.id, CurrentUser.user, :replacement_accepted, post_replacement_id: id, old_md5: previous_md5, new_md5: md5)
      end
      creator.notify_for_upload(self, :replacement_approve) if creator_id != CurrentUser.id
      post.update_index
    end

    def toggle_penalize!
      unless approved?
        errors.add(:status, "must be approved to penalize")
        return
      end

      if penalize_uploader_on_approve
        User.where(id: uploader_on_approve).update_all("own_post_replaced_penalize_count = own_post_replaced_penalize_count - 1")
      else
        User.where(id: uploader_on_approve).update_all("own_post_replaced_penalize_count = own_post_replaced_penalize_count + 1")
      end
      update_attribute(:penalize_uploader_on_approve, !penalize_uploader_on_approve)
    end

    def promote!
      unless pending?
        errors.add(:status, "must be pending to promote")
        return
      end

      upload = transaction do
        upload = CurrentUser.scoped(creator, creator_ip_addr) { create_upload }
        if upload.blank?
          raise(ProcessingError, "Failed to create upload")
        elsif upload.errors.any?
          raise(ProcessingError, "Failed to create upload: #{upload.errors.full_messages.join(', ')}")
        elsif upload.upload_media_asset.errors.any?
          raise(ProcessingError, "Failed to create media asset: #{upload.upload_media_asset.errors.full_messages.join(', ')}")
        elsif !upload.upload_media_asset.active?
          raise(ProcessingError, "Failed to create media asset: #{upload.upload_media_asset.status_message.presence || upload.upload_media_asset.status}")
        elsif upload.post.blank?
          raise(ProcessingError, "Failed to create post")
        elsif upload.post.errors.any?
          raise(ProcessingError, "Failed to create post: #{upload.post.errors.full_messages.join(', ')}")
        end

        update_columns(status: "promoted")
        PostEvent.add!(upload.post.id, CurrentUser.user, :replacement_promoted, source_post_id: post_id, post_replacement_id: id)

        creator.notify_for_upload(self, :replacement_promote) if creator_id != CurrentUser.id
        upload
      end
      upload.post.update_index
      upload
    end

    def reject!(user = CurrentUser.user, reason = "")
      unless pending?
        errors.add(:status, "must be pending to reject")
        return
      end

      PostEvent.add!(post.id, user, :replacement_rejected, post_replacement_id: id)
      update(status: "rejected", rejector: user, rejection_reason: reason)
      User.where(id: creator_id).update_all("post_replacement_rejected_count = post_replacement_rejected_count + 1")
      creator.notify_for_upload(self, :replacement_reject) if creator_id != CurrentUser.id
      post.update_index
    end
  end

  module PromotionMethods
    def new_upload_params(replace: false)
      {
        uploader_id:      creator_id,
        uploader_ip_addr: creator_ip_addr,
        file:             media_asset.get_file,
        tag_string:       post.tag_string,
        rating:           post.rating,
        source:           "#{source}\n" + post.source,
        parent_id:        post.id,
        description:      post.description,
        locked_tags:      post.locked_tags,
        is_replacement:   replace,
        replacement_id:   id,
      }
    end
  end

  module SearchMethods
    def search(params)
      q = super

      q = q.joins(:post_replacement_media_asset).where("post_replacement_media_assets.file_ext": params[:file_ext]) if params[:file_ext]
      q = q.joins(:post_replacement_media_asset).where("post_replacement_media_assets.md5": params[:md5]) if params[:md5]
      q = q.attribute_exact_matches(:status, params[:status])

      q = q.where_user(:creator_id, :creator, params)
      q = q.where_user(:approver_id, :approver, params)
      q = q.where_user(:rejector_id, :rejector, params)
      q = q.where_user(:uploader_id_on_approve, %i[uploader_name_on_approve uploader_id_on_approve], params)

      if params[:post_id].present?
        q = q.where("post_replacements.post_id in (?)", params[:post_id].split(",").first(100).map(&:to_i))
      end

      q.apply_basic_order(params)
    end

    def default_order
      order(Arel.sql("CASE post_replacements.status WHEN 'pending' THEN 0 WHEN 'original' THEN 2 ELSE 1 END ASC, id DESC"))
    end

    def visible(user)
      return not_rejected if user.is_anonymous?
      return all if user.is_staff?
      where(creator_id: user.id).or(not_rejected)
    end
  end

  def original_file_visible_to?(user)
    user.is_janitor?
  end

  def upload_as_pending?
    as_pending.to_s.truthy?
  end

  include(StorageMethods)
  include(FileMethods)
  include(ProcessingMethods)
  include(PromotionMethods)
  include(PostMethods)
  extend(SearchMethods)

  def file_url
    if post.deleteblocked?
      nil
    elsif post.visible?
      if original_file_visible_to?(CurrentUser)
        replacement_file_url
      else
        replacement_thumb_url
      end
    end
  end

  def post_details
    {
      width:  post.image_width,
      height: post.image_height,
      size:   post.file_size,
      ext:    post.file_ext,
      md5:    post.md5,
    }
  end

  def current_details
    {
      width:  image_width,
      height: image_width,
      size:   file_size,
      ext:    file_ext,
      md5:    md5,
    }
  end

  def show_current?
    post && (pending? || previous_details.blank?)
  end

  def details
    if pending? && post
      post_details
    elsif previous_details.blank?
      return post_details if post
      nil
    else
      previous_details.transform_keys(&:to_sym)
    end
  end

  def sequence
    post.replacement_ids.reverse.index(id)
  end

  def self.available_includes
    %i[creator approver rejector post uploader_on_approve]
  end
end
