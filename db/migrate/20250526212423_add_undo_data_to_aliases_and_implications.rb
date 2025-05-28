# frozen_string_literal: true

class AddUndoDataToAliasesAndImplications < ActiveRecord::Migration[7.1]
  def change
    add_column(:tag_aliases, :undo_data, :jsonb, null: false, default: [])
    add_column(:tag_implications, :undo_data, :jsonb, null: false, default: [])
  end
end
