# frozen_string_literal: true

class TagVersionPolicy < ApplicationPolicy
  def permitted_search_params
    params = super + %i[tag_id tag_name updater_id updater_name] + nested_search_params(updater: User, tag: Tag)
    params << :ip_addr if can_search_ip_addr?
    params
  end
end
