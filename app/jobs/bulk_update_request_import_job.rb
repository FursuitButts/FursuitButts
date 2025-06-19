# frozen_string_literal: true

class BulkUpdateRequestImportJob < ApplicationJob
  queue_as(:tags)

  def perform(*)
    BulkUpdateRequestImport.new(*).process!
  end
end
