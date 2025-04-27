# frozen_string_literal: true

FactoryBot.define do
  factory(:mascot_media_asset) do
    creator { create(:user, created_at: 2.weeks.ago) }
    creator_ip_addr { "127.0.0.1" }
    checksum { SecureRandom.hex(16) }

    factory(:jpg_mascot_media_asset) do
      checksum { "ecef68c44edb8a0d6a3070b5f8e8ee76" }
      md5 { "ecef68c44edb8a0d6a3070b5f8e8ee76" }
      file_ext { "jpg" }
      is_animated_png { false }
      is_animated_gif { false }
      file_size { 28_086 }
      image_width { 500 }
      image_height { 335 }
      pixel_hash { "01cb481ec7730b7cfced57ffa5abd196" }
      status { "active" }
      file { fixture_file_upload("test.jpg") }
    end

    # height > 1000
    # factory(:png_mascot_media_asset) do
    #   checksum { "081a5c3b92d8980d1aadbd215bfac5b9" }
    #   md5 { "081a5c3b92d8980d1aadbd215bfac5b9" }
    #   file_ext { "png" }
    #   is_animated_png { false }
    #   is_animated_gif { false }
    #   file_size { 446148 }
    #   image_width { 768 }
    #   image_height { 1024 }
    #   pixel_hash { "d351db38efb2697d355cf89853099539" }
    #   status { "active" }
    #   file { fixture_file_upload("test.png") }
    # end
  end
end
