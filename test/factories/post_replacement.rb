# frozen_string_literal: true

FactoryBot.define do
  factory(:post_replacement) do
    creator { create(:user, created_at: 2.weeks.ago) }
    creator_ip_addr { "127.0.0.1" }
    sequence(:reason) { |n| "post_replacement_reason#{n}" }
    post_replacement_media_asset { build(:random_post_replacement_media_asset, creator: creator, creator_ip_addr: creator_ip_addr) }

    factory(:url_replacement) do
      direct_url { "http://www.google.com/intl/en_ALL/images/logo.gif" }
    end

    factory(:file_replacement) do
      file { fixture_file_upload("test.jpg") }
    end

    factory(:webm_replacement) do
      post_replacement_media_asset { build(:webm_post_replacement_media_asset, :pending, creator: creator, creator_ip_addr: creator_ip_addr) }
      file { |rec| rec.post_replacement_media_asset&.file }
    end

    factory(:mp4_replacement) do
      post_replacement_media_asset { build(:mp4_post_replacement_media_asset, :pending, creator: creator, creator_ip_addr: creator_ip_addr) }
      file { |rec| rec.post_replacement_media_asset&.file }
    end

    factory(:jpg_replacement) do
      post_replacement_media_asset { build(:jpg_post_replacement_media_asset, :pending, creator: creator, creator_ip_addr: creator_ip_addr) }
      file { |rec| rec.post_replacement_media_asset&.file }
    end

    factory(:jpg_invalid_replacement) do
      post_replacement_media_asset { build(:jpg_invalid_post_replacement_media_asset, :pending, creator: creator, creator_ip_addr: creator_ip_addr) }
      file { |rec| rec.post_replacement_media_asset&.file }
    end

    factory(:gif_replacement) do
      post_replacement_media_asset { build(:gif_post_replacement_media_asset, :pending, creator: creator, creator_ip_addr: creator_ip_addr) }
      file { |rec| rec.post_replacement_media_asset&.file }
    end

    factory(:empty_replacement) do
      post_replacement_media_asset { build(:empty_post_replacement_media_asset, :pending, creator: creator, creator_ip_addr: creator_ip_addr) }
      file { |rec| rec.post_replacement_media_asset&.file }
    end

    factory(:png_replacement) do
      post_replacement_media_asset { build(:png_post_replacement_media_asset, :pending, creator: creator, creator_ip_addr: creator_ip_addr) }
      file { |rec| rec.post_replacement_media_asset&.file }
    end

    factory(:apng_replacement) do
      post_replacement_media_asset { build(:apng_post_replacement_media_asset, :pending, creator: creator, creator_ip_addr: creator_ip_addr) }
      file { |rec| rec.post_replacement_media_asset&.file }
    end
  end
end
