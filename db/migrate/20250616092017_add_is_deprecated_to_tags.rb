# frozen_string_literal: true

class AddIsDeprecatedToTags < ActiveRecord::Migration[7.1]
  def change
    add_column(:tags, :is_deprecated, :boolean, null: false, default: false)
    add_column(:tag_versions, :is_deprecated, :boolean, null: false, default: false)
    change_column_default(:tag_versions, :is_deprecated, from: false, to: nil)
  end
end
