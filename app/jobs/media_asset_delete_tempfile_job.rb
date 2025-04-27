# frozen_string_literal: true

class MediaAssetDeleteTempfileJob < ApplicationJob
  queue_as :default

  def perform(asset)
    asset.remove_tempfile!
  end
end
