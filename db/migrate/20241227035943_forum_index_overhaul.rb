# frozen_string_literal: true

class ForumIndexOverhaul < ActiveRecord::Migration[7.1]
  def change
    add_column(:forum_categories, :description, :text, null: false, default: "")
    add_column(:forum_categories, :topic_count, :integer, null: false, default: 0)
    add_column(:forum_categories, :post_count, :integer, null: false, default: 0)
  end
end
