# frozen_string_literal: true

class PoolVersionPolicy < ApplicationPolicy
  def diff?
    index?
  end

  def permitted_search_params
    params = super + %i[updater_id updater_name pool_id is_active] + nested_search_params(updater: User, pool: Pool)
    params += %i[ip_addr] if can_search_ip_addr?
    params
  end
end
