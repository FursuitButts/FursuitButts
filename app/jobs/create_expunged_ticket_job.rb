# frozen_string_literal: true

class CreateExpungedTicketJob < ApplicationJob
  queue_as(:default)

  def perform(klass, id, duplicate_ids)
    CurrentUser.as_system do
      asset = klass.constantize.find(id)
      duplicates = klass.constantize.where(id: duplicate_ids)
      klass.constantize.notify_expunged_reupload(asset, duplicates)
    end
  end
end
