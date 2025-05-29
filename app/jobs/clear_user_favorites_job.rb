# frozen_string_literal: true

class ClearUserFavoritesJob < ApplicationJob
  queue_as(:default)

  def perform(user)
    FavoriteManager.remove_all!(user: user)
  end
end
