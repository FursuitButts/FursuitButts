# frozen_string_literal: true

class CreateUserApprovals < ActiveRecord::Migration[7.1]
  def change
    create_table(:user_approvals) do |t|
      t.references(:updater, foreign_key: { to_table: :users })
      t.references(:user, foreign_key: true, null: false)
      t.string(:status, null: false, default: "pending")
      t.timestamps
    end
  end
end
