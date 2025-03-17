# frozen_string_literal: true

class AddTypedTagStringToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column(:posts, :typed_tag_string, :string, null: false, default: "")
  end
end
