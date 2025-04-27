# frozen_string_literal: true

FactoryBot.define do
  factory(:post) do
    uploader { create(:user, created_at: 2.weeks.ago) }
    uploader_ip_addr { "127.0.0.1" }
    tag_string { "tag1 tag2" }
    tag_count { 2 }
    tag_count_general { 2 }
    sequence(:source) { |n| "https://example.com/#{n}" }
    media_asset { create(:random_upload_media_asset, creator: uploader, creator_ip_addr: uploader_ip_addr) }
  end

  factory(:webm_post) do
    media_asset { create(:webm_upload_media_asset, :active, creator: uploader, creator_ip_addr: uploader_ip_addr) }
  end

  factory(:mp4_post) do
    media_asset { create(:mp4_upload_media_asset, :active, creator: uploader, creator_ip_addr: uploader_ip_addr) }
  end

  factory(:jpg_post) do
    media_asset { create(:jpg_upload_media_asset, :active, creator: uploader, creator_ip_addr: uploader_ip_addr) }
  end

  factory(:jpg_invalid_post) do
    media_asset { create(:jpg_invalid_upload_media_asset, :active, creator: uploader, creator_ip_addr: uploader_ip_addr) }
  end

  factory(:gif_post) do
    media_asset { create(:gif_upload_media_asset, :active, creator: uploader, creator_ip_addr: uploader_ip_addr) }
  end

  factory(:png_post) do
    media_asset { create(:png_upload_media_asset, :active, creator: uploader, creator_ip_addr: uploader_ip_addr) }
  end

  factory(:apng_post) do
    media_asset { create(:apng_upload_media_asset, :active, creator: uploader, creator_ip_addr: uploader_ip_addr) }
  end
end
