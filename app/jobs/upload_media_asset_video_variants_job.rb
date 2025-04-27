# frozen_string_literal: true

class UploadMediaAssetVideoVariantsJob < ApplicationJob
  queue_as :variants
  sidekiq_options lock: :until_executed, lock_args_method: :lock_args, retry: 3

  def self.lock_args(args)
    [args[0]]
  end

  def perform(id)
    asset = UploadMediaAsset.find(id)
    raise(StandardError, "upload is still in progress") if asset.in_progress?
    asset.open_file do |file|
      UploadMediaAssetVariantsJob.generate_videos(file, asset)
    end
  end
end
