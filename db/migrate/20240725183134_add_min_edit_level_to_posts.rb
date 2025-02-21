# frozen_string_literal: true

class AddMinEditLevelToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column(:posts, :min_edit_level, :integer, null: false, default: User::Levels::MEMBER)
  end
end
