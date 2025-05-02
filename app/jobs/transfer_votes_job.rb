# frozen_string_literal: true

class TransferVotesJob < ApplicationJob
  queue_as :low

  def perform(*args)
    @post = Post.find_by(id: args[0])
    @user = User.find_by(id: args[1])
    unless @post && @user
      # Something went wrong and there is nothing we can do inside the job.
      return
    end

    CurrentUser.scoped(@user) do
      @post.give_votes_to_parent!
    end
  end
end
