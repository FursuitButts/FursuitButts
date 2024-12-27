# frozen_string_literal: true

class PostVote < LockableUserVote
  validate :validate_user_can_vote

  def self.model_creator_column
    :uploader
  end

  def validate_user_can_vote
    if !user.can_post_downvote? && score == -1
      errors.add(:user, "cannot downvote posts")
      return false
    end
    allowed = user.can_post_vote_with_reason
    if allowed != true
      errors.add(:user, User.throttle_reason(allowed))
      return false
    end
    true
  end

  def self.available_includes
    %i[post user]
  end
end
