# frozen_string_literal: true

class AddCoverPostToPools < ActiveRecord::Migration[7.1]
  def change
    # we need this for the includes(cover_post: :media_asset)
    add_reference(:pools, :cover_post, foreign_key: { to_table: :posts }, null: true)
  end
end
