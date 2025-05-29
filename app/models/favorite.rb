# frozen_string_literal: true

class Favorite < ApplicationRecord
  class Error < StandardError; end

  belongs_to(:post)
  belongs_to(:user, counter_cache: "favorite_count")
  # FavoriteManager depends on this validation not existing
  # validates :post_id, uniqueness: { scope: :user_id }
  scope(:for_user, ->(user_id) { where(user_id: user_id.to_i) })
  scope(:for_posts, ->(post_ids) { where(post_id: post_ids) })

  def self.available_includes
    %i[posts user]
  end
end
