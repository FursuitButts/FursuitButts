# frozen_string_literal: true

class AiCheckJob < ApplicationJob
  queue_as(:high)
  sidekiq_options(lock: :until_executing)

  def perform(post)
    post.ai_check!
  end
end
