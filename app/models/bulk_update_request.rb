# frozen_string_literal: true

class BulkUpdateRequest < ApplicationRecord
  belongs_to_creator
  attr_accessor :reason, :skip_forum, :should_validate

  belongs_to :forum_topic, optional: true
  belongs_to :forum_post, optional: true
  belongs_to :approver, optional: true, class_name: "User"

  validates :script, presence: true
  validates :title, presence: { if: ->(rec) { rec.forum_topic_id.blank? } }
  validates :status, inclusion: { in: %w[pending approved rejected] }
  validate :script_formatted_correctly
  validate :forum_topic_id_not_invalid
  validate :validate_script, on: :create
  validate :check_validate_script, on: :update
  validates :reason, length: { minimum: 5, maximum: FemboyFans.config.forum_post_max_size }, on: :create, unless: :skip_forum
  before_validation :normalize_text
  after_create :create_forum_topic

  scope :pending_first, -> { order(Arel.sql("(case status when 'pending' then 0 when 'approved' then 1 else 2 end)")) }
  scope :pending, -> { where(status: "pending") }

  module SearchMethods
    def for_creator(id)
      where(creator_id: id)
    end

    def default_order
      pending_first.order(id: :desc)
    end

    def search(params)
      q = super

      q = q.where_user(:creator_id, :creator, params)
      q = q.where_user(:approver_id, :approver, params)

      if params[:forum_topic_id].present?
        q = q.where(forum_topic_id: params[:forum_topic_id].split(",").map(&:to_i))
      end

      if params[:forum_post_id].present?
        q = q.where(forum_post_id: params[:forum_post_id].split(",").map(&:to_i))
      end

      if params[:status].present?
        q = q.where(status: params[:status].split(","))
      end

      q = q.attribute_matches(:title, params[:title_matches])
      q = q.attribute_matches(:script, params[:script_matches])

      params[:order] ||= "status_desc"
      case params[:order]
      when "updated_at_desc"
        q = q.order(updated_at: :desc)
      when "updated_at_asc"
        q = q.order(updated_at: :asc)
      else
        q = q.apply_basic_order(params)
      end

      q
    end
  end

  module ApprovalMethods
    def forum_updater
      @forum_updater ||= ForumUpdater.new(
        forum_topic,
        forum_post:     (forum_post || forum_topic.posts.first if forum_topic),
        expected_title: title,
        skip_update:    !TagRelationship::SUPPORT_HARD_CODED,
      )
    end

    def approve!(approver)
      transaction do
        CurrentUser.scoped(approver) do
          BulkUpdateRequestImporter.new(script, forum_topic_id, creator_id, creator_ip_addr).process!
          update(status: "approved", approver: CurrentUser.user)
          forum_updater.update("The #{bulk_update_request_link} (forum ##{forum_post&.id}) has been approved by @#{approver.name}.", "APPROVED")
        end
      end
    rescue BulkUpdateRequestImporter::Error => e
      self.approver = approver
      CurrentUser.scoped(approver) do
        forum_updater.update("The #{bulk_update_request_link} (forum ##{forum_post&.id}) has failed: #{e}", "FAILED")
      end
      errors.add(:base, e.to_s)
    end

    def create_forum_topic
      return if skip_forum
      if forum_topic_id
        forum_post = forum_topic.posts.create(body: "Reason: #{reason}")
        update(forum_post_id: forum_post.id)
      else
        forum_topic = ForumTopic.create(title: title, category_id: FemboyFans.config.alias_implication_forum_category, original_post_attributes: { body: "Reason: #{reason}" })
        forum_post = forum_topic.posts.first
        update(forum_topic_id: forum_topic.id, forum_post_id: forum_post.id)
      end
      forum_post.update(tag_change_request: self, allow_voting: true)
    end

    def reject!(rejector = User.system)
      transaction do
        update(status: "rejected")
        forum_updater.update("The #{bulk_update_request_link} (forum ##{forum_post&.id}) has been rejected by @#{rejector.name}.", "REJECTED")
      end
    end

    def bulk_update_request_link
      %("bulk update request ##{id}":/bulk_update_requests/#{id})
    end
  end

  module ValidationMethods
    def script_formatted_correctly
      BulkUpdateRequestImporter.tokenize(script)
      true
    rescue StandardError => e
      errors.add(:base, e.message)
      false
    end

    def forum_topic_id_not_invalid
      if forum_topic_id && !forum_topic
        errors.add(:base, "Forum topic ID is invalid")
      end
    end

    def check_validate_script
      validate_script if should_validate
    end

    def validate_script
      errors, new_script = BulkUpdateRequestImporter.new(script, forum_topic_id).validate!(CurrentUser.user)
      unless errors.empty?
        errors.each { |err| self.errors.add(:base, err) }
      end
      self.script = new_script

      errors.empty?
    rescue BulkUpdateRequestImporter::Error => e
      self.errors.add(:script, e)
    end
  end

  extend SearchMethods
  include ApprovalMethods
  include ValidationMethods

  concerning :EmbeddedText do
    class_methods do
      def embedded_pattern
        /\[bur:(?<id>\d+)\]/m
      end
    end
  end

  def editable?(user)
    is_pending? && (creator_id == user.id || user.can_manage_aibur?)
  end

  def approvable?(user)
    return false unless is_pending? && user.can_manage_aibur?
    (creator_id != user.id || user.is_admin?) && FemboyFans.config.tag_change_request_update_limit(user) >= estimate_update_count
  end

  def rejectable?(user)
    is_pending? && editable?(user)
  end

  def normalize_text
    self.script = script.downcase
  end

  def skip_forum=(value) # rubocop:disable Lint/DuplicateMethods
    @skip_forum = value.to_s.truthy?
  end

  def is_pending?
    status == "pending"
  end

  def is_approved?
    status == "approved"
  end

  def is_rejected?
    status == "rejected"
  end

  def estimate_update_count
    BulkUpdateRequestImporter.new(script, nil).estimate_update_count
  end

  def self.available_includes
    %i[approver creator forum_post forum_topic]
  end
end
