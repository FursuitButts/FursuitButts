# frozen_string_literal: true

class CreateMediaMetadata < ActiveRecord::Migration[7.1]
  def change
    create_table(:media_metadata) do |t|
      t.jsonb(:meatadata, null: false, default: {})
      t.timestamps
    end
  end
end
