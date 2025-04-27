# frozen_string_literal: true

require "tmpdir"

class Upload < ApplicationRecord
  class Error < StandardError; end
  has_media_asset(:upload_media_asset)

  attr_accessor :as_pending, :original_post_id, :locked_rating, :locked_tags, :is_replacement, :replacement_id

  belongs_to :uploader, class_name: "User"
  belongs_to :post, optional: true

  after_initialize :set_locked_tags
  before_validation :assign_rating_from_tags
  before_validation :normalize_direct_url, on: :create

  validate :uploader_is_not_limited, on: :create
  validate :direct_url_is_whitelisted, on: :create
  validate :no_excessive_pending_uploads, on: :create
  validates :rating, inclusion: { in: %w[q e s] }, allow_nil: false

  scope :pending, -> { joins(:upload_media_asset).where("upload_media_asset.status": "pending") }
  scope :uploading, -> { joins(:upload_media_asset).where("upload_media_asset.status": "uploading") }
  scope :completed, -> { joins(:upload_media_asset).where("upload_media_asset.status": "active") }
  scope :in_progress, -> { joins(:upload_media_asset).where("upload_media_asset.status": %w[pending uploading]) }

  delegate :duplicate_post_id, :status, :status_message, :pretty_status,
           :pending?, :uploading?, :active?, :deleted?, :cancelled?, :expunged?, :failed?, :duplicate?, to: :media_asset, allow_nil: true

  def set_locked_tags
    self.locked_tags ||= ""
  end

  module DirectURLMethods
    def normalize_direct_url
      return if direct_url.blank?
      self.direct_url = direct_url.unicode_normalize(:nfc)
      if direct_url =~ %r{\Ahttps?://}i
        self.direct_url = begin
          Addressable::URI.normalized_encode(direct_url)
        rescue StandardError
          direct_url
        end
      end
      self.direct_url = begin
        Sources::Strategies.find(direct_url).canonical_url
      rescue StandardError
        direct_url
      end
    end

    def direct_url_parsed
      return nil unless direct_url =~ %r{\Ahttps?://}i
      begin
        Addressable::URI.heuristic_parse(direct_url)
      rescue StandardError
        nil
      end
    end
  end

  module UploaderMethods
    def uploader_name
      User.id_to_name(uploader_id)
    end
  end

  module SearchMethods
    def post_tags_match(query)
      where(post_id: Post.tag_match_sql(query))
    end

    def search(params)
      q = super

      q = q.where_user(:uploader_id, :uploader, params)

      if params[:source].present?
        q = q.where(source: params[:source])
      end

      if params[:source_matches].present?
        q = q.where("uploads.source LIKE ? ESCAPE E'\\\\'", params[:source_matches].to_escaped_for_sql_like)
      end

      if params[:rating].present?
        q = q.where(rating: params[:rating])
      end

      if params[:parent_id].present?
        q = q.attribute_matches(:parent_id, params[:parent_id])
      end

      if params[:post_id].present?
        q = q.attribute_matches(:post_id, params[:post_id])
      end

      if params[:has_post].to_s.truthy?
        q = q.where.not(post_id: nil)
      elsif params[:has_post].to_s.falsy?
        q = q.where(post_id: nil)
      end

      if params[:post_tags_match].present?
        q = q.post_tags_match(params[:post_tags_match])
      end

      if params[:status].present?
        q = q.joins(:upload_media_asset).where("upload_media_asset.status": params[:status])
      end

      if params[:backtrace].present?
        q = q.where("uploads.backtrace LIKE ? ESCAPE E'\\\\'", params[:backtrace].to_escaped_for_sql_like)
      end

      if params[:tag_string].present?
        q = q.where("uploads.tag_string LIKE ? ESCAPE E'\\\\'", params[:tag_string].to_escaped_for_sql_like)
      end

      q.apply_basic_order(params)
    end
  end

  include UploaderMethods
  include DirectURLMethods
  extend SearchMethods

  def uploader_is_not_limited
    return if replacement_id.present?
    uploadable = uploader.can_upload_with_reason
    if uploadable != true
      errors.add(:uploader, User.upload_reason_string(uploadable))
      return false
    end
    true
  end

  def no_excessive_pending_uploads
    if Upload.in_progress.where(uploader_id: uploader_id).count >= FemboyFans.config.pending_uploads_limit
      errors.add(:base, "You have too many pending uploads. Finish or cancel your existing uploads and try again")
      return false
    end
    true
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

  def assign_rating_from_tags
    if (rating = TagQuery.fetch_metatag(tag_string, "rating"))
      self.rating = rating.downcase.first
    end
  end

  def presenter
    @presenter ||= UploadPresenter.new(self)
  end

  def upload_as_pending?
    as_pending.to_s.truthy?
  end

  def visible?(user = CurrentUser.user)
    user.is_janitor?
  end

  def convert_to_post
    Post.new.tap do |p|
      p.tag_string = tag_string
      p.original_tag_string = tag_string
      p.locked_tags = locked_tags
      p.is_rating_locked = locked_rating if locked_rating.present?
      p.description = description.strip
      p.rating = rating
      p.source = source
      p.uploader_id = uploader_id
      p.uploader_ip_addr = uploader_ip_addr
      p.parent_id = parent_id
      p.upload_url = direct_url
      p.media_asset = media_asset

      if !uploader.unrestricted_uploads? || (!uploader.can_approve_posts? && p.avoid_posting_artists.any?) || upload_as_pending?
        p.is_pending = true
      end
    end
  end

  # this overrides a rails method, but we should never need it
  def create_post
    return post if reload_post.present?
    @post = convert_to_post
    @post.save!
    update(post_id: @post.id)
    reload_post
    @post.reload
  end

  def self.available_includes
    %i[post uploader]
  end
end
