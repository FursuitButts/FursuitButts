# frozen_string_literal: true

class ArtistUrlPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[artist_name url_matches normalized_url_matches is_active order] + nested_search_params(artist: Artist)
  end
end
