# frozen_string_literal: true

class AddMascotsDisplayNameIndex < ActiveRecord::Migration[7.1]
  def change
    add_index(:mascots, "lower(display_name)", unique: true)
  end
end
