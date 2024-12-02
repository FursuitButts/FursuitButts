# frozen_string_literal: true

class PostVotePolicy < LockableUserVotePolicy
  def create?
    unbanned?
  end

  def destroy?
    unbanned?
  end

  protected

  def model
    PostVote
  end
end
