# frozen_string_literal: true

class AddContributorTagCategory < ActiveRecord::Migration[7.1]
  def change
    remove_column(:posts, :tag_count_voice_actor, :integer, default: 0, null: false)
    add_column(:posts, :tag_count_contributor, :integer, default: 0, null: false)
  end
end
