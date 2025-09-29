# frozen_string_literal: true

class TagVersionPolicy < ApplicationPolicy
  def permitted_search_params
    %i[tag_id updater_id updater_name] + nested_search_params(updater: User, tag: Tag)
  end
end
