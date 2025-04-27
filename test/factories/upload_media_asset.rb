# frozen_string_literal: true

def get_generated_variants(rec)
  rec.variants.without(rec.original).map(&:type).uniq
end

def get_variants_data(rec)
  rec.variants.without(rec.original).map { |v| { type: v.type, width: v.scaled_dimensions.first, height: v.scaled_dimensions.last, size: 100.kilobytes, md5: SecureRandom.hex(16), ext: v.ext, video: v.video? } }
end

FactoryBot.define do
  factory(:upload_media_asset) do
    creator { create(:user, created_at: 2.weeks.ago) }
    creator_ip_addr { "127.0.0.1" }
    checksum { SecureRandom.hex(16) }

    factory(:random_upload_media_asset) do
      md5 { checksum }
      file_ext { "jpg" }
      is_animated_png { false }
      is_animated_gif { false }
      file_size { 1.megabyte }
      image_width { 1000 }
      image_height { 1000 }
      pixel_hash { checksum }
      status { "active" }
      skip_files { true }
      generated_variants(&method(:get_generated_variants))
      variants_data(&method(:get_variants_data))
    end

    factory(:jpg_upload_media_asset) do
      checksum { "ecef68c44edb8a0d6a3070b5f8e8ee76" }
      file { fixture_file_upload("test.jpg") }
      pending

      trait(:pending) do
        status { "pending" }
      end

      trait(:active) do
        md5 { "ecef68c44edb8a0d6a3070b5f8e8ee76" }
        file_ext { "jpg" }
        is_animated_png { false }
        is_animated_gif { false }
        file_size { 28_086 }
        image_width { 500 }
        image_height { 335 }
        pixel_hash { "01cb481ec7730b7cfced57ffa5abd196" }
        status { "active" }
        skip_files { true }
        generated_variants(&method(:get_generated_variants))
        variants_data(&method(:get_variants_data))
      end
    end

    factory(:png_upload_media_asset) do
      checksum { "081a5c3b92d8980d1aadbd215bfac5b9" }
      file { fixture_file_upload("test.png") }
      pending

      trait(:pending) do
        status { "pending" }
      end

      trait(:active) do
        md5 { "081a5c3b92d8980d1aadbd215bfac5b9" }
        file_ext { "png" }
        is_animated_png { false }
        is_animated_gif { false }
        file_size { 446_148 }
        image_width { 768 }
        image_height { 1024 }
        pixel_hash { "d351db38efb2697d355cf89853099539" }
        status { "active" }
        skip_files { true }
        generated_variants(&method(:get_generated_variants))
        variants_data(&method(:get_variants_data))
      end
    end

    factory(:apng_upload_media_asset) do
      checksum { "0c7758e594a1d9b83d79e03a8709bedf" }
      file { fixture_file_upload("apng/normal_apng.png") }
      pending

      trait(:pending) do
        status { "pending" }
      end

      trait(:active) do
        md5 { "0c7758e594a1d9b83d79e03a8709bedf" }
        file_ext { "png" }
        is_animated_png { true }
        is_animated_gif { false }
        file_size { 6679 }
        image_width { 150 }
        image_height { 150 }
        status { "active" }
        skip_files { true }
        generated_variants(&method(:get_generated_variants))
        variants_data(&method(:get_variants_data))
      end
    end

    factory(:webp_upload_media_asset) do
      checksum { "291654feb88606970e927f32b08e2621" }
      file { fixture_file_upload("test.webp") }
      pending

      trait(:pending) do
        status { "pending" }
      end

      trait(:active) do
        md5 { "291654feb88606970e927f32b08e2621" }
        file_ext { "webp" }
        is_animated_png { false }
        is_animated_gif { false }
        file_size { 27_650 }
        image_width { 386 }
        image_height { 395 }
        pixel_hash { "39225408c7673a19a5c69f596c0d1032" }
        status { "active" }
        skip_files { true }
        generated_variants(&method(:get_generated_variants))
        variants_data(&method(:get_variants_data))
      end
    end

    factory(:gif_upload_media_asset) do
      checksum { "05f1c7a0466a4e6a2af1eef3387f4dbe" }
      file { fixture_file_upload("test.gif") }
      pending

      trait(:pending) do
        status { "pending" }
      end

      trait(:active) do
        md5 { "05f1c7a0466a4e6a2af1eef3387f4dbe" }
        file_ext { "gif" }
        is_animated_png { false }
        is_animated_gif { true }
        file_size { 203_616 }
        image_width { 1000 }
        image_height { 685 }
        pixel_hash { "516e3ef761c48e70036fb7cba973bb99" }
        status { "active" }
        skip_files { true }
        generated_variants(&method(:get_generated_variants))
        variants_data(&method(:get_variants_data))
      end
    end

    factory(:mp4_upload_media_asset) do
      checksum { "865c93102cad3e8a893d6aac6b51b0d2" }
      file { fixture_file_upload("test-300x300.mp4") }
      pending

      trait(:pending) do
        status { "pending" }
      end

      trait(:active) do
        md5 { "865c93102cad3e8a893d6aac6b51b0d2" }
        file_ext { "mp4" }
        is_animated_png { false }
        is_animated_gif { false }
        file_size { 18_677 }
        image_width { 300 }
        image_height { 300 }
        duration { 5.7 }
        framecount { 10 }
        status { "active" }
        skip_files { true }
        generated_variants(&method(:get_generated_variants))
        variants_data(&method(:get_variants_data))
      end
    end

    factory(:webm_upload_media_asset) do
      checksum { "34dd2489f7aaa9e57eda1b996ff26ff7" }
      file { fixture_file_upload("test-512x512.webm") }
      pending

      trait(:pending) do
        status { "pending" }
      end

      trait(:active) do
        md5 { "34dd2489f7aaa9e57eda1b996ff26ff7" }
        file_ext { "webm" }
        is_animated_png { false }
        is_animated_gif { false }
        file_size { 12_345 }
        image_width { 512 }
        image_height { 512 }
        duration { 0.48 }
        framecount { 24 }
        status { "active" }
        skip_files { true }
        generated_variants(&method(:get_generated_variants))
        variants_data(&method(:get_variants_data))
      end
    end

    factory(:jpg_invalid_upload_media_asset) do
      checksum { "7df25d6181c015d4cf3e003d5d84a0d9" }
      file { fixture_file_upload("test-corrupt.jpg") }
      pending

      trait(:pending) do
        status { "pending" }
      end
    end

    factory(:empty_upload_media_asset) do
      checksum { "d41d8cd98f00b204e9800998ecf8427e" }
      file { fixture_file_upload("empty.jpg") }
      pending

      trait(:pending) do
        status { "pending" }
      end
    end
  end
end
