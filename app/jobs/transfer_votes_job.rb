# frozen_string_literal: true

class TransferVotesJob < ApplicationJob
  queue_as(:low)

  def perform(post, user)
    post.give_votes_to_parent!(user)
  end
end
