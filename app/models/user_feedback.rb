# frozen_string_literal: true

class UserFeedback < ApplicationRecord
  belongs_to :user
  belongs_to_creator
  belongs_to_updater
  normalizes :body, with: ->(body) { body.gsub("\r\n", "\n") }
  validates :body, :category, presence: true
  validates :category, inclusion: { in: %w[positive negative neutral] }
  validates :body, length: { minimum: 1, maximum: FemboyFans.config.user_feedback_max_size }
  validate :creator_is_moderator, on: :create
  validate :user_is_not_creator
  after_create :log_create
  after_update :log_update
  after_destroy :log_destroy

  attr_accessor :send_update_notification

  scope :active, -> { where(is_deleted: false) }
  scope :deleted, -> { where(is_deleted: true) }

  module LogMethods
    def log_create
      ModAction.log!(:user_feedback_create, self, user_id: user_id, reason: body, type: category)
      user.notifications.create!(category: "feedback_create", data: { user_id: CurrentUser.user.id, record_id: id, record_type: category })
    end

    def log_update
      details = { user_id: user_id, reason: body, old_reason: body_before_last_save, type: category, old_type: category_before_last_save, record_id: id }
      if saved_change_to_is_deleted?
        action = is_deleted? ? :user_feedback_delete : :user_feedback_undelete
        ModAction.log!(action, self, **details)
        user.notifications.create!(category: action[5..], data: { user_id: CurrentUser.user.id, record_id: id, record_type: category })
        return unless saved_change_to_category? || saved_change_to_body?
      end
      ModAction.log!(:user_feedback_update, self, **details)
      if send_update_notification.to_s.truthy? && saved_change_to_body?
        user.notifications.create!(category: "feedback_update", data: { user_id: CurrentUser.user.id, record_id: id, record_type: category })
      end
    end

    def log_destroy
      ModAction.log!(:user_feedback_destroy, self, user_id: user_id, reason: body, type: category, record_id: id)
      deletion_user = "\"#{CurrentUser.name}\":/users/#{CurrentUser.id}"
      creator_user = "\"#{creator.name}\":/users/#{creator.id}"
      StaffNote.create(body: "#{deletion_user} destroyed #{category} feedback, created #{created_at.to_date} by #{creator_user}: #{body}", user_id: user_id, creator: User.system)
      user.notifications.create!(category: "feedback_destroy", data: { user_id: CurrentUser.user.id, record_id: id, record_type: category })
    end
  end

  module SearchMethods
    def positive
      where("category = ?", "positive")
    end

    def neutral
      where("category = ?", "neutral")
    end

    def negative
      where("category = ?", "negative")
    end

    def for_user(user_id)
      where("user_id = ?", user_id)
    end

    def default_order
      order(created_at: :desc)
    end

    def search(params)
      q = super

      deleted = (params[:deleted].presence || "excluded").downcase
      q = q.active if deleted == "excluded"
      q = q.deleted if deleted == "only"

      q = q.attribute_matches(:body, params[:body_matches])
      q = q.where_user(:user_id, :user, params)
      q = q.where_user(:creator_id, :creator, params)

      if params[:category].present?
        q = q.where("category = ?", params[:category])
      end

      q.apply_basic_order(params)
    end
  end

  include LogMethods
  extend SearchMethods

  def user_name
    User.id_to_name(user_id)
  end

  def user_name=(name)
    self.user_id = User.name_to_id(name)
  end

  def creator_is_moderator
    errors.add(:creator, "must be moderator") unless creator.is_moderator?
  end

  def user_is_not_creator
    errors.add(:creator, "cannot submit feedback for yourself") if user_id == creator_id
  end

  def editable_by?(editor)
    editor.is_moderator? && editor != user
  end

  def deletable_by?(deleter)
    deleter.is_moderator? && deleter != user
  end

  def destroyable_by?(destroyer)
    deletable_by?(destroyer) && (destroyer.is_admin? || destroyer == creator)
  end

  def self.available_includes
    %i[creator updater user]
  end

  def visible?(user = CurrentUser.user)
    user.is_moderator? || !is_deleted?
  end
end
