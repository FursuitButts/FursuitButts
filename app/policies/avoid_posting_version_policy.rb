# frozen_string_literal: true

class AvoidPostingVersionPolicy < ApplicationPolicy
  def permitted_search_params
    params = super + %i[updater_name updater_id any_name_matches artist_name artist_id any_other_name_matches is_active] + nested_search_params(updater: User, avoid_posting: AvoidPosting, artist: Artist)
    params += %i[ip_addr] if can_search_ip_addr?
    params
  end

  def api_attributes
    attr = super
    attr -= %i[staff_notes] unless user.is_janitor?
    attr
  end
end
