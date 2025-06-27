# frozen_string_literal: true

class CreateExpungedTicketJob < ApplicationJob
  queue_as(:high)

  def perform(klass, id, duplicate_ids)
    asset = klass.constantize.find(id)
    duplicates = klass.constantize.where(id: duplicate_ids)
    klass.constantize.notify_expunged_reupload(asset, duplicates)
  end
end
