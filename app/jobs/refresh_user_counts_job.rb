# frozen_string_literal: true

class RefreshUserCountsJob < ApplicationJob
  queue_as(:default)

  sidekiq_options(lock: :until_executed, lock_args_method: :lock_args)

  def self.lock_args(args)
    [args[0].id]
  end

  def perform(user)
    user.refresh_counts!
  end
end
