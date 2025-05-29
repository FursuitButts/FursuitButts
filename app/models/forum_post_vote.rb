# frozen_string_literal: true

class ForumPostVote < UserVote
  belongs_to(:forum_post)
  validates(:score, inclusion: { in: [-1, 0, 1], message: "must be 1, 0 or -1" })
  validates(:user_id, uniqueness: { scope: :forum_post_id })
  validate(:validate_user_is_not_limited, on: :create)
  scope(:by, ->(user_id) { where(user_id: user_id) })
  scope(:excluding_user, ->(user_id) { where.not(user_id: user_id) })
  scope(:for_forum_post, ->(forum_post_id) { where(forum_post_id: forum_post_id) })
  after_commit(:update_forum_post_scores)

  def update_forum_post_scores
    ForumPost.update_scores(id: forum_post_id)
  end

  def self.vote_types
    [%w[Downvote -1 text-red], %w[Meh 0 text-yellow], %w[Upvote 1 text-green]]
  end

  def self.model_creator_column
    :creator
  end

  def validate_user_is_not_limited
    allowed = user.can_forum_vote_with_reason
    if allowed != true
      errors.add(:user, User.throttle_reason(allowed))
      return false
    end
    true
  end

  def is_meh?
    score == 0
  end

  def vote_type
    if score == 0
      "meh"
    else
      super
    end
  end

  def fa_class
    if score == 1
      "fa-thumbs-up"
    elsif score == -1
      "fa-thumbs-down"
    else
      "fa-face-meh"
    end
  end

  def self.model_type
    model_name.singular.delete_suffix("_vote").to_sym
  end

  def self.available_includes
    %i[forum_post user]
  end
end
