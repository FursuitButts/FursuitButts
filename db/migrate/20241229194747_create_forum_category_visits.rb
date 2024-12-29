# frozen_string_literal: true

class CreateForumCategoryVisits < ActiveRecord::Migration[7.1]
  def change
    create_table(:forum_category_visits) do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references(:user, null: false, foreign_key: true)
      t.references(:forum_category, null: false, foreign_key: true)
      t.datetime(:last_read_at, null: false, default: -> { "CURRENT_TIMESTAMP" }, index: true)
    end
  end
end
