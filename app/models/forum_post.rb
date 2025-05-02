# frozen_string_literal: true

class ForumPost < ApplicationRecord
  include UserWarnable
  simple_versioning
  mentionable
  has_dtext_links :body
  belongs_to_creator counter_cache: "forum_post_count"
  belongs_to_updater
  belongs_to :topic, class_name: "ForumTopic"
  has_one :category, through: :topic
  belongs_to :original_topic, class_name: "ForumTopic", optional: true
  belongs_to :warning_user, class_name: "User", optional: true
  has_many :votes, class_name: "ForumPostVote"
  has_many :tickets, as: :model
  has_many :versions, class_name: "EditHistory", as: :versionable, dependent: :destroy
  has_one :spam_ticket, -> { spam }, class_name: "Ticket", as: :model
  has_one :last_edit_version, -> { where(edit_type: "edit").order(created_at: :desc) }, class_name: "EditHistory", as: :versionable

  belongs_to :tag_change_request, polymorphic: true, optional: true
  before_validation :initialize_is_hidden, on: :create
  before_create :auto_report_spam
  after_create :update_topic_updated_at_on_create
  # no counter cache since we're more than one association away
  after_create -> { category.increment!(:post_count) }
  after_create :log_create
  after_update :log_update
  before_destroy :validate_topic_is_unlocked
  after_destroy :update_topic_updated_at_on_destroy
  normalizes :body, with: ->(body) { body.gsub("\r\n", "\n") }
  validates :body, :creator_id, presence: true
  validates :body, length: { minimum: 1, maximum: FemboyFans.config.forum_post_max_size }
  validate :validate_topic_is_unlocked
  validate :validate_topic_id_not_invalid
  validate :validate_topic_is_not_restricted, on: :create
  validate :validate_topic_is_not_stale, on: :create
  validate :validate_category_allows_replies, on: :create
  validate :validate_creator_is_not_limited, on: :create
  validate :validate_not_aibur, if: :will_save_change_to_is_hidden?
  after_destroy -> { category.decrement!(:post_count) }
  after_destroy :log_destroy
  after_save :delete_topic_if_original_post

  attr_accessor :bypass_limits, :is_merging

  scope :votable, -> { where(allow_voting: true) }

  module SearchMethods
    def topic_title_matches(title)
      joins(:topic).merge(ForumTopic.search(title_matches: title))
    end

    def for_user(user_id)
      where("forum_posts.creator_id = ?", user_id)
    end

    def visible(user)
      active(user).permitted(user)
    end

    def not_visible(user)
      where.not(id: visible(user))
    end

    def permitted(user)
      q = joins(topic: :category).where("forum_categories.can_view <= ?", user.level)
      q = q.joins(:topic).where("forum_topics.is_hidden = FALSE OR forum_topics.creator_id = ?", user.id) unless user.is_moderator?
      q
    end

    def active(user)
      return all if user.is_moderator?
      where("forum_posts.is_hidden = FALSE OR forum_posts.creator_id = ?", user.id)
    end

    def search(params)
      q = super
      q = q.where_user(:creator_id, :creator, params)

      if params[:topic_id].present?
        q = q.where("forum_posts.topic_id": params[:topic_id])
      end

      if params[:topic_title_matches].present?
        q = q.topic_title_matches(params[:topic_title_matches])
      end

      q = q.attribute_matches(:body, params[:body_matches])

      if params[:topic_category_id].present?
        q = q.joins(:topic).where("forum_topics.category_id": params[:topic_category_id])
      end

      if params[:linked_to].present?
        q = q.linked_to(params[:linked_to])
      end

      if params[:not_linked_to].present?
        q = q.not_linked_to(params[:not_linked_to])
      end

      q = q.attribute_matches(:is_hidden, params[:is_hidden])

      case params[:order]
      when "updated_at_desc"
        q = q.order(updated_at: :desc)
      when "updated_at_asc"
        q = q.order(updated_at: :asc)
      when "rating_desc"
        q = q.order(percentage_score: :desc, id: :desc)
      when "rating_asc"
        q = q.order(percentage_score: :asc, id: :desc)
      when "score_desc"
        q = q.order(total_score: :desc, id: :desc)
      when "score_asc"
        q = q.order(total_score: :asc, id: :desc)
      else
        q.apply_basic_order(params)
      end

      q
    end
  end

  module LogMethods
    def log_create
      log_voting_change if saved_change_to_allow_voting?
    end

    def log_update
      log_voting_change if saved_change_to_allow_voting?

      if saved_change_to_is_hidden?
        ModAction.log!(is_hidden? ? :forum_post_hide : :forum_post_unhide, self, forum_topic_id: topic_id, user_id: creator_id)
      end

      if !saved_change_to_is_hidden? && updater_id != creator_id && !is_merging
        ModAction.log!(:forum_post_update, self, forum_topic_id: topic_id, user_id: creator_id)
      end
    end

    def log_destroy
      ModAction.log!(:forum_post_delete, self, forum_topic_id: topic_id, user_id: creator_id)
    end

    def log_voting_change
      if allow_voting?
        save_version("enabled_voting")
      else
        save_version("disabled_voting")
      end
    end
  end

  extend SearchMethods
  include LogMethods

  def has_voting?
    allow_voting?
  end

  def voting_active?
    has_voting? && (!is_aibur? || tag_change_request.is_pending?)
  end

  def is_aibur?
    tag_change_request.present?
  end

  def validate_topic_is_unlocked
    return if CurrentUser.is_moderator? || topic.nil?

    if topic.is_locked?
      errors.add(:topic, "is locked")
      throw(:abort)
    end
  end

  def validate_creator_is_not_limited
    return if bypass_limits

    allowed = creator.can_forum_post_with_reason
    if allowed != true
      errors.add(:creator, User.throttle_reason(allowed))
      throw(:abort)
    end
  end

  def validate_not_aibur
    return if CurrentUser.is_moderator? || !is_aibur?

    if is_hidden?
      errors.add(:post, "is for an alias, implication, or bulk update request. It cannot be hidden")
      throw(:abort)
    end
  end

  def validate_topic_is_not_stale
    return if !topic&.is_stale_for?(CurrentUser.user) || bypass_limits
    errors.add(:topic, "is stale. New posts cannot be created")
    throw(:abort)
  end

  def validate_topic_id_not_invalid
    if topic_id && !topic
      errors.add(:topic_id, "is invalid")
      throw(:abort)
    end
  end

  def validate_topic_is_not_restricted
    if topic && !topic.visible?(creator)
      errors.add(:topic, "is restricted")
      throw(:abort)
    end
  end

  def validate_category_allows_replies
    if topic && !topic.can_reply?(creator)
      errors.add(:topic, "does not allow replies")
      throw(:abort)
    end
  end

  def editable_by?(user)
    return true if user.is_admin?
    return false if was_warned? || (is_aibur? && !tag_change_request.is_pending?)
    creator_id == user.id && visible?(user)
  end

  def can_hide?(user)
    return true if user.is_moderator?
    return false if is_aibur?
    return false if was_warned?
    user.id == creator_id
  end

  def can_delete?(user)
    user.is_admin?
  end

  def update_topic_updated_at_on_create
    if topic
      # need to do this to bypass the topic's original post from getting touched
      t = Time.now
      ForumTopic.where(id: topic.id).update_all(["updater_id = ?, response_count = response_count + 1, updated_at = ?, last_post_created_at = ?", CurrentUser.id, t, t])
      topic.response_count += 1
    end
  end

  def hide!
    update(is_hidden: true)
    update_topic_updated_at_on_hide
  end

  def unhide!
    update(is_hidden: false)
    update_topic_updated_at_on_hide
  end

  def update_topic_updated_at_on_hide
    max = ForumPost.where(topic_id: topic.id, is_hidden: false).order("updated_at desc").first
    if max
      ForumTopic.where(id: topic.id).update_all(["updated_at = ?, updater_id = ?", max.updated_at, max.updater_id])
    end
  end

  def update_topic_updated_at_on_destroy
    max = ForumPost.where(topic_id: topic.id, is_hidden: false).order("updated_at desc").first
    if max
      ForumTopic.where(id: topic.id).update_all(["response_count = response_count - 1, updated_at = ?, updater_id = ?", max.updated_at, max.updater_id])
    else
      ForumTopic.where(id: topic.id).update_all("response_count = response_count - 1")
    end
    topic.response_count -= 1
  end

  def initialize_is_hidden
    self.is_hidden = false if is_hidden.nil?
  end

  def forum_topic_page
    Cache.fetch("fp_topic_page:#{id}", expires_in: 12.hours) do
      (ForumPost.where("topic_id = ? and created_at <= ?", topic_id, created_at).count / FemboyFans.config.records_per_page.to_f).ceil
    end
  end

  def is_original_post?(original_post_id = nil)
    if original_post_id
      id == original_post_id
    else
      ForumPost.exists?(["id = ? and id = (select _.id from forum_posts _ where _.topic_id = ? order by _.id asc limit 1)", id, topic_id])
    end
  end

  def delete_topic_if_original_post
    if is_hidden? && is_original_post?
      topic.update_attribute(:is_hidden, true)
    end

    true
  end

  def hidden_at
    return nil unless is_hidden?
    versions.hidden.last&.created_at
  end

  def warned_at
    return nil unless was_warned?
    versions.marked.last&.created_at
  end

  def edited_at
    last_edit_version&.created_at
  end

  def auto_report_spam
    if SpamDetector.new(self, user_ip: creator_ip_addr.to_s).spam?
      self.is_spam = true
      tickets << Ticket.new(creator: User.system, creator_ip_addr: "127.0.0.1", reason: "Spam.")
    end
  end

  def mark_spam!
    return if is_spam?
    update!(is_spam: true)
    return if spam_ticket.present?
    SpamDetector.new(self, user_ip: creator_ip_addr.to_s).spam!
  end

  def mark_not_spam!
    return unless is_spam?
    update!(is_spam: false)
    return if spam_ticket.blank?
    SpamDetector.new(self, user_ip: creator_ip_addr.to_s).ham!
  end

  def self.available_includes
    %i[creator updater topic dtext_links tag_change_request]
  end

  def visible?(user = CurrentUser.user)
    topic.visible?(user) && (user.is_moderator? || !is_hidden? || user.id == creator_id)
  end

  def is_merged?
    merged_at.present?
  end

  def self.update_scores(id: nil)
    if id.present? && ForumPostVote.for_forum_post(id).count == 0
      ForumPost.where(id: id).update_all("total_score = 0, percentage_score = 0, total_votes = 0, up_votes = 0, down_votes = 0, meh_votes = 0")
      return
    end
    # yes, I spent far too long on this
    query = <<~SQL.squish.strip
      UPDATE forum_posts
      SET total_score = votes.total_score,
          percentage_score = CASE
              WHEN votes.total_count > 0
              THEN (votes.up_count * 100.0) / votes.total_count
              ELSE 0
          END,
          total_votes = votes.total_count,
          up_votes = votes.up_count,
          down_votes = votes.down_count,
          meh_votes = votes.meh_count
      FROM (
          SELECT forum_post_id,
                 SUM(score) AS total_score,
                 COUNT(*) AS total_count,
                 COUNT(*) FILTER (WHERE score = 1) AS up_count,
                 COUNT(*) FILTER (WHERE score = -1) AS down_count,
                 COUNT(*) FILTER (WHERE score = 0) AS meh_count
          FROM forum_post_votes
          #{id ? "WHERE forum_post_id = #{id}" : ''}
          GROUP BY forum_post_id
      ) AS votes
      WHERE forum_posts.id = votes.forum_post_id;
    SQL
    ForumPost.connection.execute(query)
  end
end
