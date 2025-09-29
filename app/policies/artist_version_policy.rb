# frozen_string_literal: true

class ArtistVersionPolicy < ApplicationPolicy
  def permitted_search_params
    params = super + %i[updater_name updater_id artist_name artist_id order] + nested_search_params(updater: User)
    params += %i[ip_addr] if can_search_ip_addr?
    params
  end
end
