# frozen_string_literal: true

class IpBanPolicy < ApplicationPolicy
  def index?
    user.is_admin?
  end

  def create?
    user.is_admin?
  end

  def destroy?
    user.is_admin?
  end

  def permitted_attributes
    %i[ip_addr reason]
  end

  def permitted_search_params
    super + %i[ip_addr creator_id creator_name creator_ip_addr reason] + nested_search_params(creator: User)
  end
end
