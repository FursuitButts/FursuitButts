# frozen_string_literal: true

require "fileutils"

FactoryBot.define do
  factory(:upload) do
    rating { "s" }
    uploader { create(:user, created_at: 2.weeks.ago) }
    uploader_ip_addr { "127.0.0.1" }
    tag_string { "tagme" }
    # status { "pending" }
    source { "xxx" }
    upload_media_asset { build(:random_upload_media_asset, creator: uploader, creator_ip_addr: uploader_ip_addr) }

    factory(:url_upload) do
      direct_url { "http://www.google.com/intl/en_ALL/images/logo.gif" }
    end

    factory(:file_upload) do
      file { fixture_file_upload("test.jpg") }
    end

    factory(:webm_upload) do
      upload_media_asset { build(:webm_upload_media_asset, :pending, creator: uploader, creator_ip_addr: uploader_ip_addr) }
      file { |rec| rec.upload_media_asset&.file }
    end

    factory(:mp4_upload) do
      upload_media_asset { build(:mp4_upload_media_asset, :pending, creator: uploader, creator_ip_addr: uploader_ip_addr) }
      file { |rec| rec.upload_media_asset&.file }
    end

    factory(:jpg_upload) do
      upload_media_asset { build(:jpg_upload_media_asset, :pending, creator: uploader, creator_ip_addr: uploader_ip_addr) }
      file { |rec| rec.upload_media_asset&.file }
    end

    factory(:jpg_invalid_upload) do
      upload_media_asset { build(:jpg_invalid_upload_media_asset, :pending, creator: uploader, creator_ip_addr: uploader_ip_addr) }
      file { |rec| rec.upload_media_asset&.file }
    end

    factory(:gif_upload) do
      upload_media_asset { build(:gif_upload_media_asset, :pending, creator: uploader, creator_ip_addr: uploader_ip_addr) }
      file { |rec| rec.upload_media_asset&.file }
    end

    factory(:png_upload) do
      upload_media_asset { build(:png_upload_media_asset, :pending, creator: uploader, creator_ip_addr: uploader_ip_addr) }
      file { |rec| rec.upload_media_asset&.file }
    end

    factory(:apng_upload) do
      upload_media_asset { build(:apng_upload_media_asset, :pending, creator: uploader, creator_ip_addr: uploader_ip_addr) }
      file { |rec| rec.upload_media_asset&.file }
    end

    factory(:empty_upload) do
      upload_media_asset { build(:empty_upload_media_asset, :pending, creator: uploader, creator_ip_addr: uploader_ip_addr) }
      file { |rec| rec.upload_media_asset&.file }
    end
  end
end
