# frozen_string_literal: true

module ExtendedMigration
  def self.[](version)
    Class.new(ActiveRecord::Migration[version]) do
      include(MigrationHelpers)
    end
  end
end
