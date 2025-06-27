# frozen_string_literal: true

# reverts all changes made by a user
class UserRevert
  THRESHOLD = 1_000
  class TooManyChangesError < RuntimeError; end

  attr_reader(:user_id, :current_user)

  def initialize(user_id, current_user)
    @user_id = user_id
    @current_user = current_user
  end

  def process
    validate!
    revert_post_changes
  end

  def validate!
    if PostVersion.where(updater_id: user_id).count > THRESHOLD
      raise(TooManyChangesError, "This user has too many changes to be reverted")
    end
  end

  def revert_post_changes
    PostVersion.where(updater_id: user_id).find_each do |version|
      version.undo!(current_user) if version.undoable?
    end
  end

  def self.can_revert?(user)
    user.post_update_count <= THRESHOLD
  end
end
