# frozen_string_literal: true

module VoteManager
  module ForumPosts
    module_function

    def vote!(user:, forum_post:, score:)
      forum_post_vote = forum_post.votes.find_by(user: user)
      if forum_post_vote.present?
        forum_post_vote.update(score: params[:score]) if forum_post_vote.score != params[:score]
      else
        forum_post_vote = forum_post.votes.create(score: score)
        raise(User::PrivilegeError, forum_post_vote.errors.full_messages.join("; ")) unless forum_post_vote.errors.empty?
      end
      forum_post_vote
    end

    def unvote!(user:, forum_post:)
      ForumPostVote.transaction(**ISOLATION) do
        ForumPostVote.uncached do
          vote = ForumPostVote.where(user_id: user.id, forum_post_id: forum_post.id).first
          raise(VoteManager::NoVoteError) unless vote
          ForumPostVote.where(user_id: user.id, forum_post_id: forum_post.id).delete_all
        end
      end
    rescue VoteManager::NoVoteError
      # Ignored
    end

    def admin_unvote!(id)
      vote = ForumPostVote.find_by(id: id)
      return unless vote
      StaffAuditLog.log!(:forum_post_vote_delete, CurrentUser.user, forum_post_id: vote.forum_post_id, vote: vote.score, voter_id: vote.user_id)
      unvote!(forum_post: vote.forum_post, user: vote.user)
    end
  end
end
