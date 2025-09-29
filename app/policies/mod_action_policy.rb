# frozen_string_literal: true

class ModActionPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[creator_id creator_name action subject_type subject_id]
  end

  def api_attributes
    super - %i[values] + record.json_keys + nested_search_params(creator: User)
  end
end
