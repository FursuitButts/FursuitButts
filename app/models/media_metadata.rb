# frozen_string_literal: true

class MediaMetadata < ApplicationRecord
  has_one(:upload_media_asset)
  has_one(:post_replacement_media_asset)
  has_one(:mascot_media_asset)
end
