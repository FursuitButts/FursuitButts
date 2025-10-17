# frozen_string_literal: true

class AddNoteToPostFlags < ExtendedMigration[7.1]
  def change
    add_column(:post_flags, :note, :string)
  end
end
