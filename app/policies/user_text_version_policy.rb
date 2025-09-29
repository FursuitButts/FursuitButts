# frozen_string_literal: true

class UserTextVersionPolicy < ApplicationPolicy
  def index?
    user.is_moderator?
  end

  def for_user?
    index?
  end

  def diff?
    index?
  end

  def blacklist?
    user.is_admin? || (record.is_a?(UserTextVersion) && record.user_id == user.id)
  end

  def permitted_search_params
    params = super + %i[changes updater_id updater_name user_id user_name about_matches artinfo_matches] + nested_search_params(user: User, updater: User)
    params += %i[ip_addr] if can_search_ip_addr?
    params += %i[blacklist_matches] if user.is_admin?
    params
  end

  def permitted_attributes
    %i[score]
  end
end
