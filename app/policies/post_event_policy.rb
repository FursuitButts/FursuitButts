# frozen_string_literal: true

class PostEventPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[post_id creator_id creator_name action] + nested_search_params(post: Post)
  end

  def api_attributes
    super - %i[extra_data] + record.json_keys
  end
end
