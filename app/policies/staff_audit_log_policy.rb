# frozen_string_literal: true

class StaffAuditLogPolicy < ApplicationPolicy
  def index?
    user.is_moderator?
  end

  def permitted_search_params
    super + %i[user_id user_name action] + nested_search_params(user: User)
  end

  def api_attributes
    super - %i[values] + record.json_keys
  end
end
