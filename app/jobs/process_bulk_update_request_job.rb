# frozen_string_literal: true

class ProcessBulkUpdateRequestJob < ApplicationJob
  queue_as(:tags)
  sidekiq_options(lock: :until_executed, lock_args_method: :lock_args)

  def self.lock_args(args)
    [args[0].id]
  end

  def perform(bur, approver, update_topic)
    bur.process!(approver, update_topic: update_topic)
  end
end
