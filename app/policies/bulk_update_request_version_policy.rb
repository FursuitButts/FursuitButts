# frozen_string_literal: true

class BulkUpdateRequestVersionPolicy < ApplicationPolicy
  def diff?
    index?
  end

  def undo?
    return member? unless record.is_a?(BulkUpdateRequestVersion) && record.bulk_update_request.is_a?(BulkUpdateRequest)
    policy(record.bulk_update_request).update?
  end

  def permitted_search_params
    params = super + %i[updater_id updater_name bulk_update_request_id] + nested_search_params(updater: User, bulk_update_request: BulkUpdateRequest)
    params += %i[ip_addr] if can_search_ip_addr?
    params
  end
end
