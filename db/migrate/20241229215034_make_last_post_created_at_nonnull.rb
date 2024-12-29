# frozen_string_literal: true

class MakeLastPostCreatedAtNonnull < ActiveRecord::Migration[7.1]
  def change
    change_column_default(:forum_topics, :last_post_created_at, from: nil, to: -> { "CURRENT_TIMESTAMP" })
    change_column_null(:forum_topics, :last_post_created_at, false)
  end
end
