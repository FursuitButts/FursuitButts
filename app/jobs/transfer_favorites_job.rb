# frozen_string_literal: true

class TransferFavoritesJob < ApplicationJob
  queue_as(:low)

  def perform(post, user)
    post.give_favorites_to_parent!(user)
  end
end
