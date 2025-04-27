# frozen_string_literal: true

class CreatePostReplacementMediaAssets < ActiveRecord::Migration[7.1]
  def change
    create_table(:post_replacement_media_assets) do |t|
      t.references(:creator, foreign_key: { to_table: :users }, null: false)
      t.references(:media_metadata, foreign_key: true, null: false)
      t.inet(:creator_ip_addr, null: false)
      t.string(:checksum, limit: 32, null: true, index: true)
      t.string(:md5, limit: 32, null: true, index: true) # only set when completed, no unique index
      t.string(:file_ext, limit: 4, null: true) # only set when completed
      t.boolean(:is_animated_png, null: true) # rubocop:disable Rails/ThreeStateBooleanColumn # only set when completed
      t.boolean(:is_animated_gif, null: true) # rubocop:disable Rails/ThreeStateBooleanColumn # only set when completed
      t.integer(:file_size, null: true) # only set when completed
      t.integer(:image_width, null: true) # only set when completed
      t.integer(:image_height, null: true) # only set when completed
      t.numeric(:duration) # only set when completed
      t.integer(:framecount) # only set when completed
      t.string(:pixel_hash, limit: 32, null: true, index: true) # only set when completed
      t.string(:status, default: "pending", null: false)
      t.string(:status_message, null: true)
      t.string(:storage_id, null: false, index: { unique: true })
      t.integer(:last_chunk_id, null: false, default: 0)
      t.jsonb(:generated_variants, null: false, default: [])
      t.jsonb(:variants_data, null: false, default: [])
      t.timestamps
    end
    add_reference(:post_replacements, :post_replacement_media_asset, foreign_key: true, null: true) # will be made nonnull after a fixer is run
    change_column_default(:post_replacements, :status, from: "pending", to: "uploading")
  end
end
