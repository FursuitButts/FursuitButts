# frozen_string_literal: true

class AddUserVoteCounters < ActiveRecord::Migration[7.1]
  def change
    add_column(:users, :post_vote_count, :integer, default: 0, null: false)
    add_column(:users, :comment_vote_count, :integer, default: 0, null: false)
    add_column(:users, :forum_post_vote_count, :integer, default: 0, null: false)
  end
end
