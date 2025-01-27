# frozen_string_literal: true

class AddAllowVotingToForumPosts < ActiveRecord::Migration[7.1]
  def change
    add_column(:forum_posts, :allow_voting, :boolean, default: false, null: false)
  end
end
