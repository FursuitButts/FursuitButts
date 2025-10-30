# frozen_string_literal: true

class UserNameChangeRequestPolicy < ApplicationPolicy
  def index?
    user.is_moderator?
  end

  def create?
    unbanned?
  end

  def show?
    unbanned? && (record.user_id == user.id || user.is_janitor?)
  end

  def permitted_attributes
    %i[desired_name change_reason]
  end

  def permitted_search_params
    params = super + %i[user_id user_name creator_id creator_name approver_id approver_name original_name desired_name] + nested_search_params(user: User, creator: User, approver: User)
    params << :ip_addr if can_search_ip_addr?
    params
  end
end
