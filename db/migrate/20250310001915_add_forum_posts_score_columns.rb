# frozen_string_literal: true

class AddForumPostsScoreColumns < ActiveRecord::Migration[7.1]
  def change
    add_column(:forum_posts, :total_score, :integer, default: 0, null: false)
    add_column(:forum_posts, :percentage_score, :numeric, precision: 2, default: 0, null: false)
    add_column(:forum_posts, :total_votes, :integer, default: 0, null: false)
    add_column(:forum_posts, :up_votes, :integer, default: 0, null: false)
    add_column(:forum_posts, :down_votes, :integer, default: 0, null: false)
    add_column(:forum_posts, :meh_votes, :integer, default: 0, null: false)
  end
end
