# frozen_string_literal: true

module VoteManager
  module Comments
    module_function

    def vote!(user:, comment:, score:)
      retries = 5
      @vote = nil
      score = score.to_i
      begin
        raise(UserVote::Error, "Invalid vote") unless [1, -1].include?(score)
        raise(UserVote::Error, "You do not have permission to vote") unless user.can_comment_vote?
        raise(UserVote::Error, "Comment section is disabled") if comment.post.is_comment_disabled?
        raise(UserVote::Error, "Comment section is locked") if comment.post.is_comment_locked?
        CommentVote.transaction(**ISOLATION) do
          CommentVote.uncached do
            score_modifier = score
            @vote = CommentVote.where(user_id: user.id, comment_id: comment.id).first
            if @vote
              raise(UserVote::Error, "Vote is locked") if @vote.is_locked?
              raise(VoteManager::NeedUnvoteError) if @vote.score == score
              score_modifier *= 2
              @vote.destroy
            end
            @vote = CommentVote.create!(user_id: user.id, score: score, comment_id: comment.id)
            Comment.where(id: comment.id).update_all("score = score + #{score_modifier}")
          end
        end
      rescue ActiveRecord::SerializationFailure
        retries -= 1
        retry if retries > 0
        raise(UserVote::Error, "Failed to vote, please try again later.")
      rescue ActiveRecord::RecordNotUnique
        raise(UserVote::Error, "You have already voted for this comment")
      rescue VoteManager::NeedUnvoteError
        return [@vote, :need_unvote]
      end
      [@vote, nil]
    end

    def unvote!(user:, comment:, force: false)
      CommentVote.transaction(**ISOLATION) do
        CommentVote.uncached do
          vote = CommentVote.where(user_id: user.id, comment_id: comment.id).first
          raise(VoteManager::NoVoteError) unless vote
          raise(UserVote::Error, "You can't remove locked votes") if vote.is_locked? && !force
          CommentVote.where(user_id: user.id, comment_id: comment.id).delete_all
          Comment.where(id: comment.id).update_all("score = score - #{vote.score}")
        end
      end
    rescue VoteManager::NoVoteError
      # Ignored
    end

    def lock!(id)
      CommentVote.transaction(**ISOLATION) do
        vote = CommentVote.find_by(id: id)
        raise(VoteManager::NoVoteError) unless vote
        StaffAuditLog.log!(:comment_vote_lock, CurrentUser.user, comment_id: vote.comment_id, vote: vote.score, voter_id: vote.user_id)
        Comment.where(id: vote.comment_id).update_all("score = score - #{vote.score}")
        vote.update_columns(is_locked: true)
      end
    rescue VoteManager::NoVoteError
      # Ignored
    end

    def admin_unvote!(id)
      vote = CommentVote.find_by(id: id)
      return unless vote
      StaffAuditLog.log!(:comment_vote_delete, CurrentUser.user, comment_id: vote.comment_id, vote: vote.score, voter_id: vote.user_id)
      unvote!(comment: vote.comment, user: vote.user, force: true)
    end
  end
end
