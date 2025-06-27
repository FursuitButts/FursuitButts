# frozen_string_literal: true

class NotifyExpungedMediaAssetReuploadJob < ApplicationJob
  queue_as(:high)

  def perform(user, text)
    Ticket.create!(model: user.resolve, reason: text, creator: User.system, creator_ip_addr: "127.0.0.1").push_pubsub("create")
  end
end
