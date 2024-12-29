# frozen_string_literal: true

class DropForumTopicVisits < ActiveRecord::Migration[7.1]
  def change
    drop_table(:forum_topic_visits) do |t|
      t.references(:user, foreign_key: true)
      t.references(:forum_topic, foreign_key: true)
      t.datetime(:last_read_at, index: true)
      t.timestamps
    end
  end
end
