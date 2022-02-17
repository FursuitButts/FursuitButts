class CustomProps < ActiveRecord::Migration[6.1]
  def change
	add_column :users, :display_name, :string, :null => false

	execute "CREATE UNIQUE INDEX index_users_on_display_name ON users ((lower(display_name)))"
  end
end
