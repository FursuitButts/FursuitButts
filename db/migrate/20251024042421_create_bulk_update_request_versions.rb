# frozen_string_literal: true

class CreateBulkUpdateRequestVersions < ActiveRecord::Migration[7.1]
  def change
    create_table(:bulk_update_request_versions) do |t|
      t.references(:bulk_update_request, foreign_key: true, null: false)
      t.references(:updater, foreign_key: { to_table: :users }, null: false)
      t.inet(:updater_ip_addr, null: false)
      t.string(:script, null: false)
      t.boolean(:script_changed, null: false, default: false)
      t.string(:status, null: false)
      t.boolean(:status_changed, null: false, default: false)
      t.string(:title, null: false)
      t.boolean(:title_changed, null: false, default: false)
      t.integer(:version, :integer, null: false, default: 1)
      t.timestamps
    end
  end
end
