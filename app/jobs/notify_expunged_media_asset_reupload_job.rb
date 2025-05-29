# frozen_string_literal: true

class NotifyExpungedMediaAssetReuploadJob < ApplicationJob
  queue_as(:default)

  def perform(user, text)
    CurrentUser.as_system do
      Ticket.create!(model: user, reason: text).push_pubsub("create")
    end
  end
end
