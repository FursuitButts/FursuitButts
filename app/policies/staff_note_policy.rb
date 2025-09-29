# frozen_string_literal: true

class StaffNotePolicy < ApplicationPolicy
  def can_view?
    user.is_staff?
  end

  def index?
    can_view?
  end

  def create?
    can_view?
  end

  def update?
    return true if user.is_owner? && !record&.is_deleted?
    return false unless can_view?
    return true if record.blank?
    !record.is_deleted? && record.creator_id == user.id
  end

  def destroy?
    return true if user.is_owner? && !record&.is_deleted?
    return false unless can_view?
    return true if record.blank?
    return true if user.is_owner? || record.creator_id == user.id
    record.user_id != user.id
  end

  def undelete?
    destroy?
  end

  def permitted_attributes
    %i[body]
  end

  def permitted_search_params
    super + %i[creator_id creator_name updater_id updater_name user_id user_name body_matches without_system_user include_deleted] + nested_search_params(user: User)
  end
end
