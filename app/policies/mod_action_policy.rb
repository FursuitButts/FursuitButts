# frozen_string_literal: true

class ModActionPolicy < ApplicationPolicy
  def permitted_search_params
    params = super + %i[creator_id creator_name action subject_type subject_id] + nested_search_params(creator: User)
    params << :ip_addr if can_search_ip_addr?
    params
  end

  def api_attributes
    super - %i[values] + record.json_keys
  end
end
