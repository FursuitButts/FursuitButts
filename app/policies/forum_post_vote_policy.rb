# frozen_string_literal: true

class ForumPostVotePolicy < UserVotePolicy
  def create?
    return member? unless record.is_a?(ForumPost)
    policy(record).min_level? && member?
  end

  protected

  def model
    ForumPostVote
  end
end
