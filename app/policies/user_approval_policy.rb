# frozen_string_literal: true

class UserApprovalPolicy < ApplicationPolicy
  def index?
    user.is_moderator?
  end

  def approve?
    user.is_admin? && (!record.is_a?(UserApproval) || record.is_approvable?)
  end

  def reject?
    user.is_admin? && (!record.is_a?(UserApproval) || record.is_rejectable?)
  end

  def permitted_search_params
    super + %i[user_name user_id updater_name updater_id status] + nested_search_params(user: User, updater: User)
  end
end
