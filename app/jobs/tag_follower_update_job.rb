# frozen_string_literal: true

class TagFollowerUpdateJob < ApplicationJob
  queue_as(:followers)

  def perform(post_id)
    post = Post.find(post_id)
    TagFollower.update_from_post!(post)
  end
end
