# frozen_string_literal: true

class DmailPolicy < ApplicationPolicy
  def index?
    restricted_access? || unbanned?
  end

  def create?
    restricted_access? || unbanned?
  end

  def show?
    (restricted_access? || unbanned?) && (!record.is_a?(Dmail) || record.visible_to?(user))
  end

  def respond?
    (restricted_access? || unbanned?) && (!record.is_a?(Dmail) || (record.visible_to?(user) && record.owner_id == user.id))
  end

  def destroy?
    (restricted_access? || unbanned?) && (!record.is_a?(Dmail) || record.owner_id == user.id)
  end

  def mark_spam?
    user.is_moderator? && (!record.is_a?(Dmail) || record.visible_to?(user))
  end

  def mark_not_spam?
    user.is_moderator? && (!record.is_a?(Dmail) || record.visible_to?(user))
  end

  def mark_as_read?
    (restricted_access? || unbanned?) && (!record.is_a?(Dmail) || record.owner_id == user.id)
  end

  def mark_as_unread?
    (restricted_access? || unbanned?) && (!record.is_a?(Dmail) || record.owner_id == user.id)
  end

  def mark_all_as_read?
    restricted_access? || unbanned?
  end

  def restricted_access?
    !user.is_banned? && (user.is_restricted? || user.is_rejected?)
  end

  def permitted_attributes
    %i[title body to_name to_id]
  end

  def permitted_search_params
    (super - %i[order]) + %i[title_matches message_matches to_name to_id from_name from_id is_read is_deleted read owner_id owner_name]
  end

  def api_attributes
    super - %i[key]
  end
end
