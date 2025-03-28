# frozen_string_literal: true

class AddPostImportIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index(:posts, :id)
    add_index(:pools, :post_ids, using: :gin)
    add_index(:comments, %i[post_id is_hidden])
    add_index(:notes, %i[post_id is_active])
    add_index(:post_votes, :score)
    add_index(:post_flags, %i[post_id is_resolved is_deletion])
    add_index(:post_replacements, %i[post_id status])
    add_index(:post_appeals, %i[post_id status])
    add_index(:artists, :linked_user_id)
  end
end
