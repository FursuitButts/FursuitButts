# frozen_string_literal: true

class AddIsAppealedToPosts < ExtendedMigration[7.1]
  def change
    add_column(:posts, :is_appealed, :boolean, null: false, default: false)
  end
end
