# frozen_string_literal: true

class UserFeedback < ApplicationRecord
  belongs_to_user(:user)
  belongs_to_user(:creator, ip: true, clones: :updater)
  belongs_to_user(:updater, ip: true)
  resolvable(:destroyer)
  soft_deletable
  normalizes(:body, with: ->(body) { body.gsub("\r\n", "\n") })
  validates(:body, :category, presence: true)
  validates(:body, length: { minimum: 1, maximum: -> { Config.instance.user_feedback_max_size } })
  validate(:creator_is_moderator, on: :create)
  validate(:user_is_not_creator)
  after_create(:log_create)
  after_update(:log_update)
  after_destroy(:log_destroy)
  enum(:category, %w[positive negative neutral].index_with(&:to_s))

  attr_accessor(:send_update_notification)

  scope(:active, -> { where(is_deleted: false) })
  scope(:deleted, -> { where(is_deleted: true) })

  module LogMethods
    def log_create
      ModAction.log!(creator, :user_feedback_create, self, user_id: user_id, reason: body, type: category)
      user.notifications.create!(category: "feedback_create", data: { user_id: updater_id, record_id: id, record_type: category })
    end

    def log_update
      details = { user_id: user_id, reason: body, old_reason: body_before_last_save, type: category, old_type: category_before_last_save, record_id: id }
      if saved_change_to_is_deleted?
        action = is_deleted? ? :user_feedback_delete : :user_feedback_undelete
        ModAction.log!(updater, action, self, **details)
        user.notifications.create!(category: action[5..], data: { user_id: updater_id, record_id: id, record_type: category })
        return unless saved_change_to_category? || saved_change_to_body?
      end
      ModAction.log!(updater, :user_feedback_update, self, **details)
      if send_update_notification.to_s.truthy? && saved_change_to_body?
        user.notifications.create!(category: "feedback_update", data: { user_id: updater_id, record_id: id, record_type: category })
      end
    end

    def log_destroy
      ModAction.log!(destroyer, :user_feedback_destroy, self, user_id: user_id, reason: body, type: category, record_id: id)
      deletion_user = "\"#{destroyer_name}\":/users/#{destroyer_id}"
      creator_user = "\"#{creator_name}\":/users/#{creator_id}"
      StaffNote.create(body: "#{deletion_user} destroyed #{category} feedback, created #{created_at.to_date} by #{creator_user}: #{body}", user_id: user_id, creator: User.system)
      user.notifications.create!(category: "feedback_destroy", data: { user_id: destroyer_id, record_id: id, record_type: category })
    end
  end

  module SearchMethods
    def default_order
      order(created_at: :desc)
    end

    def query_dsl
      super
        .field(:body_matches, :body)
        .field(:category)
        .field(:ip_addr, :creator_ip_addr)
        .field(:updater_ip_addr)
        .association(:user)
        .association(:creator)
        .association(:updater)
    end

    def search(params, user)
      q = super

      deleted = (params[:deleted].presence || "excluded").downcase
      q = q.active if deleted == "excluded"
      q = q.deleted if deleted == "only"
      q
    end
  end

  include(LogMethods)
  extend(SearchMethods)

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

  def visible?(user)
    user.is_moderator? || !is_deleted?
  end
end
