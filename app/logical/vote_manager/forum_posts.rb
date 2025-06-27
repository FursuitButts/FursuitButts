# frozen_string_literal: true

module VoteManager
  module ForumPosts
    module_function

    def vote!(user:, ip_addr:, forum_post:, score:)
      forum_post_vote = forum_post.votes.find_by(user: user)
      if forum_post_vote.present?
        forum_post_vote.update(score: score) if forum_post_vote.score != score
      else
        forum_post_vote = forum_post.votes.create(user: user, user_ip_addr: ip_addr, score: score)
        raise(User::PrivilegeError, forum_post_vote.errors.full_messages.join("; ")) unless forum_post_vote.errors.empty?
      end
      forum_post_vote
    end

    def unvote!(user:, forum_post:)
      ForumPostVote.transaction(**ISOLATION) do
        ForumPostVote.uncached do
          votes = forum_post.votes.where(user: user)
          raise(VoteManager::NoVoteError) unless votes.any?
          votes.destroy_all
        end
      end
    rescue VoteManager::NoVoteError
      # Ignored
    end

    def admin_unvote!(id, user)
      vote = ForumPostVote.find_by(id: id)
      return unless vote
      StaffAuditLog.log!(user, :forum_post_vote_delete, forum_post_id: vote.forum_post_id, vote: vote.score, voter_id: vote.user_id)
      unvote!(forum_post: vote.forum_post, user: vote.user)
    end
  end
end
