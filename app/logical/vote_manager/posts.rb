# frozen_string_literal: true

module VoteManager
  module Posts
    module_function

    def vote!(user:, post:, score:)
      @vote = nil
      retries = 5
      score = score.to_i
      begin
        raise(UserVote::Error, "Invalid vote") unless [1, -1].include?(score)
        raise(UserVote::Error, "You do not have permission to vote") unless user.can_post_vote?
        raise(UserVote::Error, "You do not have permission to downvote") if user.is_pending? && score == -1
        PostVote.transaction(**ISOLATION) do
          PostVote.uncached do
            @vote = PostVote.where(user_id: user.id, post_id: post.id).first
            if @vote
              raise(UserVote::Error, "Vote is locked") if @vote.is_locked?
              raise(VoteManager::NeedUnvoteError) if @vote.score == score
              @vote.destroy
            end
            @vote = PostVote.create!(user: user, score: score, post: post)
            post.append_user_to_vote_string(user.id, %w[down locked up].fetch(score + 1))
            post.do_not_version_changes = true
            post.save
          end
        end
      rescue ActiveRecord::SerializationFailure
        retries -= 1
        retry if retries > 0
        raise(UserVote::Error, "Failed to vote, please try again later")
      rescue ActiveRecord::RecordNotUnique
        raise(UserVote::Error, "You have already voted for this post")
      rescue VoteManager::NeedUnvoteError
        return [@vote, :need_unvote]
      end
      post.update_index
      [@vote, nil]
    end

    def unvote!(user:, post:, force: false)
      retries = 5
      begin
        PostVote.transaction(**ISOLATION) do
          PostVote.uncached do
            vote = PostVote.where(user_id: user.id, post_id: post.id).first
            raise(VoteManager::NoVoteError) unless vote
            raise(UserVote::Error, "You can't remove locked votes") if vote.is_locked? && !force
            post.votes.where(user: user).delete_all
            post.delete_user_from_vote_string(user.id)
            post.do_not_version_changes = true
            post.save
          end
        end
      rescue ActiveRecord::SerializationFailure
        retries -= 1
        retry if retries > 0
        raise(UserVote::Error, "Failed to unvote, please try again later")
      end
      post.update_index
    rescue VoteManager::NoVoteError
      # Ignored
    end

    def lock!(id)
      post = nil
      PostVote.transaction(**ISOLATION) do
        vote = PostVote.find_by(id: id)
        raise(VoteManager::NoVoteError) unless vote
        StaffAuditLog.log!(:post_vote_lock, CurrentUser.user, post_id: vote.post_id, vote: vote.score, voter_id: vote.user_id)
        post = vote.post
        post.append_user_to_vote_string(vote.user_id, "locked")
        post.do_not_version_changes = true
        post.save
        vote.update_columns(is_locked: true)
      end
      post&.update_index
    rescue VoteManager::NoVoteError
      # Ignored
    end

    def admin_unvote!(id)
      vote = PostVote.find_by(id: id)
      return unless vote
      StaffAuditLog.log!(:post_vote_delete, CurrentUser.user, post_id: vote.post_id, vote: vote.score, voter_id: vote.user_id)
      unvote!(post: vote.post, user: vote.user, force: true)
    end

    def give_to_parent!(post)
      parent = post.parent
      return false unless parent
      post.votes.each do |vote|
        next if vote.is_locked?
        tries = 5
        begin
          unvote!(user: vote.user, post: post, force: true)
          vote!(user: vote.user, post: parent, score: vote.score)
        rescue ActiveRecord::SerializationFailure
          tries -= 1
          retry if tries > 0
        end
      end
      true
    end
  end
end
