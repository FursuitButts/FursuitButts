class CustomProps < ActiveRecord::Migration[6.1]
  def change
	add_column :users, :display_name, :string, :null => false
	add_column :users, :v3_api_limit, :integer, :null => false, :default => 8

	execute "CREATE UNIQUE INDEX index_users_on_display_name ON users ((lower(display_name)))"
  end
end
