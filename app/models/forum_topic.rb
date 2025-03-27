# frozen_string_literal: true

class ForumTopic < ApplicationRecord
  class MergeError < StandardError; end

  belongs_to_creator
  belongs_to_updater
  belongs_to :category, class_name: "ForumCategory", counter_cache: "topic_count"
  belongs_to :merge_target, class_name: "ForumTopic", optional: true
  has_many :posts, -> { order(id: :asc) }, class_name: "ForumPost", foreign_key: "topic_id", dependent: :destroy
  has_one :original_post, -> { order(id: :asc) }, class_name: "ForumPost", foreign_key: "topic_id", inverse_of: :topic
  has_one :last_post, -> { order(id: :desc) }, class_name: "ForumPost", foreign_key: "topic_id", inverse_of: :topic
  has_many :statuses, class_name: "ForumTopicStatus"
  before_validation :initialize_is_hidden, on: :create
  validate :category_valid
  validates :title, :creator_id, presence: true
  validates_associated :original_post
  validates :original_post, presence: true, unless: :is_merged?
  validates :title, length: { minimum: 1, maximum: 250 }
  validate :category_allows_creation, on: :create
  validate :validate_not_aibur, if: :will_save_change_to_is_hidden?
  accepts_nested_attributes_for :original_post
  after_update :update_original_post, unless: :is_merging
  after_destroy :log_delete
  after_commit :log_save, on: %i[create update], unless: :is_merging
  after_update(if: :saved_change_to_title?) do
    Cache.delete("topic_name:#{id}")
  end

  attribute :category_id, :integer, default: -> { FemboyFans.config.default_forum_category }

  attr_accessor :is_merging, :target_topic_id

  def validate_not_aibur
    return if CurrentUser.is_moderator? || !original_post&.is_aibur?

    if is_hidden?
      errors.add(:topic, "is for an alias, implication, or bulk update request. It cannot be hidden")
      throw(:abort)
    end
  end

  module CategoryMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def for_category_id(cid)
        where(category_id: cid)
      end
    end

    def category_name
      return "(Unknown)" unless category
      category.name
    end

    def category_valid
      return if category
      errors.add(:category, "is invalid")
      throw(:abort)
    end

    def category_allows_creation
      if category && !category.can_create_within?(creator)
        errors.add(:category, "does not allow new topics")
        false
      end
    end
  end

  module LogMethods
    def log_save
      specific = false
      if saved_change_to_is_hidden?
        specific = true
        ModAction.log!(is_hidden? ? :forum_topic_hide : :forum_topic_unhide, self, forum_topic_title: title, user_id: creator_id)
      end

      if saved_change_to_is_locked?
        specific = true
        ModAction.log!(is_locked ? :forum_topic_lock : :forum_topic_unlock, self, forum_topic_title: title, user_id: creator_id)
      end

      if saved_change_to_is_sticky?
        specific = true
        ModAction.log!(is_sticky ? :forum_topic_stick : :forum_topic_unstick, self, forum_topic_title: title, user_id: creator_id)
      end

      if saved_change_to_category_id? && !previously_new_record?
        specific = true
        ModAction.log!(:forum_topic_move, self, forum_topic_title: title, user_id: creator_id, forum_category_id: category_id, forum_category_name: category.name, old_forum_category_id: category_id_before_last_save, old_forum_category_name: ForumCategory.find_by(id: category_id_before_last_save)&.name || "")
      end

      unless specific || previously_new_record? || CurrentUser.id == creator_id
        ModAction.log!(:forum_topic_update, self, forum_topic_title: title, user_id: creator_id)
      end
    end

    def log_delete
      ModAction.log!(:forum_topic_delete, self, forum_topic_title: title, user_id: creator_id)
    end
  end

  module SearchMethods
    def visible(user)
      q = joins(:category).where("forum_categories.can_view <= ?", user.level)
      q = q.where("forum_topics.is_hidden = FALSE OR forum_topics.creator_id = ?", user.id) unless user.is_moderator?
      q
    end

    def unmuted(user)
      left_outer_joins(:statuses).where("(forum_topic_statuses.mute = ? AND forum_topic_statuses.user_id = ?) OR forum_topic_statuses.id IS NULL", false, user.id)
    end

    def sticky_first
      order(is_sticky: :desc, last_post_created_at: :desc)
    end

    def default_order
      order(last_post_created_at: :desc)
    end

    def search(params)
      q = super
      q = q.visible(CurrentUser.user)

      q = q.attribute_matches(:title, params[:title_matches])
      q = q.where_user(:creator_id, :creator, params)

      if params[:category_id].present?
        q = q.for_category_id(params[:category_id])
      end

      if params[:title].present?
        q = q.where("title = ?", params[:title])
      end

      q = q.attribute_matches(:is_sticky, params[:is_sticky])
      q = q.attribute_matches(:is_locked, params[:is_locked])
      q = q.attribute_matches(:is_hidden, params[:is_hidden])

      case params[:order]
      when "sticky"
        q = q.sticky_first
      when "last_post_created_at"
        q = q.order(last_post_created_at: :desc)
      when "created_at"
        q = q.order(created_at: :desc)
      else
        q = q.apply_basic_order(params)
      end

      q
    end
  end

  module VisitMethods
    def read_by?(user = CurrentUser.user, mutes = nil)
      return true if user.is_anonymous?

      return true if mutes.present? && mutes.find { |m| m.forum_topic_id == id && m.mute }.present?

      return true if user_mute(user)
      last_read_at = category.last_read_at_for(user)

      (last_read_at && last_post_created_at <= last_read_at) || false
    end

    def mark_as_read!(user = CurrentUser.user)
      return if user.is_anonymous?

      category.mark_topic_as_read!(user, self)
    end
  end

  module SubscriptionMethods
    def user_subscription(user)
      statuses.find_by(user_id: user.id, subscription: true)
    end
  end

  module MuteMethods
    # TODO: revisit muting, it may need to be further optimized or removed due to performance issues
    def user_mute(user)
      statuses.find_by(user_id: user.id, mute: true)
    end
  end

  module MergeMethods
    def merge_into!(topic)
      raise(MergeError, "Topic is already merged") if is_merged?
      time = Time.now
      transaction do
        posts.find_each do |post|
          post.topic = topic
          post.original_topic = self
          post.merged_at = time
          post.is_merging = true
          post.save!
          post.save_version("merge", { old_topic_id: id, old_topic_title: title, new_topic_id: topic.id, new_topic_title: topic.title })
        end
        self.merge_target = topic
        self.merged_at = time
        self.is_hidden = true
        self.is_merging = true
        save!
        ModAction.log!(:forum_topic_merge, self, forum_topic_title: title, user_id: creator_id, new_topic_id: topic.id, new_topic_title: topic.title)
      end
    end

    def undo_merge!
      raise(MergeError, "Topic is not merged") unless is_merged?
      raise(MergeError, "Merge target does not exist") unless ForumTopic.exists?(id: merge_target_id)

      transaction do
        merge_target.posts.where(original_topic: self).find_each do |post|
          post.topic = self
          post.original_topic = nil
          post.merged_at = nil
          post.is_merging = true
          post.save!
          post.save_version("unmerge", { old_topic_id: merge_target.id, old_topic_title: merge_target.title, new_topic_id: id, new_topic_title: title })
        end
        target = merge_target
        self.merge_target = nil
        self.merged_at = nil
        self.is_hidden = false
        self.is_merging = true
        save!
        ModAction.log!(:forum_topic_unmerge, self, forum_topic_title: title, user_id: creator_id, old_topic_id: target.id, old_topic_title: target.title)
      end
    end

    def is_merged?
      merge_target_id.present?
    end
  end

  include LogMethods
  include CategoryMethods
  include VisitMethods
  include SubscriptionMethods
  include MuteMethods
  include MergeMethods
  extend SearchMethods

  def editable_by?(user)
    return true if user.is_admin?
    return false unless visible?(user) && original_post&.editable_by?(user)
    creator_id == user.id
  end

  def can_reply?(user = CurrentUser.user)
    user.level >= category.can_create
  end

  def can_hide?(user)
    return true if user.is_moderator?
    return false if original_post&.is_aibur?
    user.id == creator_id
  end

  def can_delete?(user)
    user.is_admin?
  end

  def initialize_is_hidden
    self.is_hidden = false if is_hidden.nil?
  end

  def last_page
    (response_count / FemboyFans.config.records_per_page.to_f).ceil
  end

  def hide!
    update(is_hidden: true)
    ModAction.without_logging { original_post&.hide! }
  end

  def unhide!
    update(is_hidden: false)
    ModAction.without_logging { original_post&.unhide! }
  end

  def update_original_post
    original_post&.update_columns(updater_id: CurrentUser.id, updated_at: Time.now)
  end

  def is_stale?
    return false unless FemboyFans.config.enable_stale_forum_topics?
    return false if !posts.many? || (original_post&.is_aibur? && (original_post&.tag_change_request&.is_pending? || posts.last.created_at < FemboyFans.config.forum_topic_aibur_stale_window.ago))
    posts.last.created_at < FemboyFans.config.forum_topic_stale_window.ago
  end

  def is_stale_for?(user)
    return false if user.is_moderator?
    is_stale?
  end

  def is_read?
    return true if CurrentUser.is_anonymous?
    return true if new_record?

    read_by?(CurrentUser.user)
  end

  def self.available_includes
    %i[category creator updater original_post]
  end

  def visible?(user = CurrentUser.user)
    (category && user.level >= category.can_view) && (user.is_moderator? || !is_hidden || creator_id == user.id)
  end
end
