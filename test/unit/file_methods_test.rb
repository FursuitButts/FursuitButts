# frozen_string_literal: true

require "test_helper"

class FileMethodsTest < ActiveSupport::TestCase
  setup do
    @jpg = file_fixture("test.jpg").to_s
    @png = file_fixture("test.png").to_s
    @apng = file_fixture("apng/normal_apng.png").to_s
    @webp = file_fixture("test.webp").to_s
    @gif = file_fixture("test.gif").to_s
    @tiff = file_fixture("test.tiff").to_s # used for invalid inputs
    @empty = Tempfile.new.path # used for empty inputs
    @mp4 = file_fixture("test-300x300.mp4").to_s
    @webm = file_fixture("test-512x512.webm").to_s
    @obj = BasicObject.include(FileMethods)
  end

  context "file_header_to_file_ext" do
    should "work" do
      assert_equal("jpg", @obj.file_header_to_file_ext(@jpg))
      assert_equal("png", @obj.file_header_to_file_ext(@png))
      assert_equal("png", @obj.file_header_to_file_ext(@apng))
      assert_equal("webp", @obj.file_header_to_file_ext(@webp))
      assert_equal("gif", @obj.file_header_to_file_ext(@gif))
      assert_equal("mp4", @obj.file_header_to_file_ext(@mp4))
      assert_equal("webm", @obj.file_header_to_file_ext(@webm))
    end

    should "return the mime type if the file extension is not specified" do
      assert_equal("image/tiff", @obj.file_header_to_file_ext(@tiff))
      assert_equal("application/octet-stream", @obj.file_header_to_file_ext(@empty))
    end
  end

  context "video" do
    should "work for videos" do
      assert_instance_of(FFMPEG::Movie, @obj.video(@mp4))
      assert_instance_of(FFMPEG::Movie, @obj.video(@webm))
    end

    should "not work for images" do
      assert_nil(@obj.video(@jpg))
      assert_nil(@obj.video(@png))
      assert_nil(@obj.video(@apng))
      assert_nil(@obj.video(@webp))
      assert_nil(@obj.video(@gif))
    end

    should "not work for invalid files" do
      assert_nil(@obj.video(@tiff))
      assert_nil(@obj.video(@empty))
    end
  end

  context "video_duration" do
    should "work for videos" do
      assert_equal(5.7, @obj.video_duration(@mp4))
      assert_equal(0.48, @obj.video_duration(@webm))
    end

    should "not work for images" do
      assert_nil(@obj.video_duration(@jpg))
      assert_nil(@obj.video_duration(@png))
      assert_nil(@obj.video_duration(@apng))
      assert_nil(@obj.video_duration(@webp))
      assert_nil(@obj.video_duration(@gif))
    end

    should "not work for invalid files" do
      assert_nil(@obj.video_duration(@tiff))
      assert_nil(@obj.video_duration(@empty))
    end
  end

  context "video_framecount" do
    should "work for videos" do
      assert_equal(10, @obj.video_framecount(@mp4))
      assert_equal(24, @obj.video_framecount(@webm))
    end

    should "not work for images" do
      assert_nil(@obj.video_framecount(@jpg))
      assert_nil(@obj.video_framecount(@png))
      assert_nil(@obj.video_framecount(@apng))
      assert_nil(@obj.video_framecount(@webp))
      assert_nil(@obj.video_framecount(@gif))
    end

    should "not work for invalid files" do
      assert_nil(@obj.video_framecount(@tiff))
      assert_nil(@obj.video_framecount(@empty))
    end
  end

  context "image" do
    should "work for images" do
      assert_instance_of(Vips::Image, @obj.image(@jpg))
      assert_instance_of(Vips::Image, @obj.image(@png))
      assert_instance_of(Vips::Image, @obj.image(@apng))
      assert_instance_of(Vips::Image, @obj.image(@webp))
      assert_instance_of(Vips::Image, @obj.image(@gif))
    end

    should "not work for videos" do
      assert_nil(@obj.image(@mp4))
      assert_nil(@obj.image(@webm))
    end

    should "not work for invalid files" do
      assert_nil(@obj.image(@tiff))
      assert_nil(@obj.image(@empty))
    end
  end

  context "calculate_dimensions" do
    should "work" do
      assert_equal([500, 335], @obj.calculate_dimensions(@jpg))
      assert_equal([768, 1024], @obj.calculate_dimensions(@png))
      assert_equal([150, 150], @obj.calculate_dimensions(@apng))
      assert_equal([386, 395], @obj.calculate_dimensions(@webp))
      assert_equal([1000, 685], @obj.calculate_dimensions(@gif))
      assert_equal([300, 300], @obj.calculate_dimensions(@mp4))
      assert_equal([512, 512], @obj.calculate_dimensions(@webm))
    end

    should "not work for invalid files" do
      assert_equal([0, 0], @obj.calculate_dimensions(@tiff))
      assert_equal([0, 0], @obj.calculate_dimensions(@empty))
    end
  end

  context "is_image?" do
    should "return true for images" do
      assert(@obj.is_image?("jpg"))
      assert(@obj.is_image?("png"))
      assert(@obj.is_image?("png")) # apng has the same extension
      assert(@obj.is_image?("webp"))
      assert(@obj.is_image?("gif"))
    end

    should "return false for videos" do
      assert_not(@obj.is_image?("mp4"))
      assert_not(@obj.is_image?("webm"))
    end

    should "return false for invalid files" do
      assert_not(@obj.is_image?("image/tiff"))
      assert_not(@obj.is_image?("application/octet-stream"))
    end
  end

  context "is_file_image?" do
    should "return true for images" do
      assert(@obj.is_file_image?(@jpg))
      assert(@obj.is_file_image?(@png))
      assert(@obj.is_file_image?(@apng))
      assert(@obj.is_file_image?(@webp))
      assert(@obj.is_file_image?(@gif))
    end

    should "return false for videos" do
      assert_not(@obj.is_file_image?(@mp4))
      assert_not(@obj.is_file_image?(@webm))
    end

    should "return false for invalid files" do
      assert_not(@obj.is_file_image?(@tiff))
      assert_not(@obj.is_file_image?(@empty))
    end
  end

  context "is_video?" do
    should "return true for videos" do
      assert(@obj.is_video?("mp4"))
      assert(@obj.is_video?("webm"))
    end

    should "return false for images" do
      assert_not(@obj.is_video?("jpg"))
      assert_not(@obj.is_video?("png"))
      assert_not(@obj.is_video?("png")) # apng has the same extension
      assert_not(@obj.is_video?("webp"))
      assert_not(@obj.is_video?("gif"))
    end

    should "return false for invalid files" do
      assert_not(@obj.is_video?("image/tiff"))
      assert_not(@obj.is_video?("application/octet-stream"))
    end
  end

  context "is_file_video?" do
    should "return true for videos" do
      assert(@obj.is_file_video?(@mp4))
      assert(@obj.is_file_video?(@webm))
    end

    should "return false for images" do
      assert_not(@obj.is_file_video?(@jpg))
      assert_not(@obj.is_file_video?(@png))
      assert_not(@obj.is_file_video?(@apng))
      assert_not(@obj.is_file_video?(@webp))
      assert_not(@obj.is_file_video?(@gif))
    end

    should "return false for invalid files" do
      assert_not(@obj.is_file_video?(@tiff))
      assert_not(@obj.is_file_video?(@empty))
    end
  end

  context "is_valid_extension?" do
    should "work" do
      assert(@obj.is_valid_extension?("jpg"))
      assert(@obj.is_valid_extension?("png"))
      assert_not(@obj.is_valid_extension?("apng")) # apng should be png
      assert(@obj.is_valid_extension?("webp"))
      assert(@obj.is_valid_extension?("gif"))
      assert(@obj.is_valid_extension?("mp4"))
      assert(@obj.is_valid_extension?("webm"))
    end

    should "not work for invalid files" do
      assert_not(@obj.is_valid_extension?("image/tiff"))
      assert_not(@obj.is_valid_extension?("application/octet-stream"))
    end
  end

  context "is_file_valid_extension?" do
    should "work" do
      assert(@obj.is_file_valid_extension?(@jpg))
      assert(@obj.is_file_valid_extension?(@png))
      assert(@obj.is_file_valid_extension?(@apng))
      assert(@obj.is_file_valid_extension?(@webp))
      assert(@obj.is_file_valid_extension?(@gif))
      assert(@obj.is_file_valid_extension?(@mp4))
      assert(@obj.is_file_valid_extension?(@webm))
    end

    should "not work for invalid files" do
      assert_not(@obj.is_file_valid_extension?(@tiff))
      assert_not(@obj.is_file_valid_extension?(@empty))
    end
  end

  context "is_animated_png?" do
    should "work" do
      assert(@obj.is_animated_png?(@apng))
    end

    should "not work for other files" do
      assert_not(@obj.is_animated_png?(@jpg))
      assert_not(@obj.is_animated_png?(@png))
      assert_not(@obj.is_animated_png?(@webp))
      assert_not(@obj.is_animated_png?(@gif))
      assert_not(@obj.is_animated_png?(@mp4))
      assert_not(@obj.is_animated_png?(@webm))
    end

    should "not work for invalid files" do
      assert_not(@obj.is_animated_png?(@tiff))
      assert_not(@obj.is_animated_png?(@empty))
    end
  end

  context "is_animated_gif?" do
    should "work" do
      assert(@obj.is_animated_gif?(@gif))
    end

    should "not work for other files" do
      assert_not(@obj.is_animated_gif?(@jpg))
      assert_not(@obj.is_animated_gif?(@png))
      assert_not(@obj.is_animated_gif?(@webp))
      assert_not(@obj.is_animated_gif?(@apng))
      assert_not(@obj.is_animated_gif?(@mp4))
      assert_not(@obj.is_animated_gif?(@webm))
    end

    should "not work for invalid files" do
      assert_not(@obj.is_animated_gif?(@tiff))
      assert_not(@obj.is_animated_gif?(@empty))
    end
  end

  context "is_corrupt?" do
    setup do
      @corrupted = file_fixture("test-corrupt.jpg")
    end

    should "work" do
      assert_not(@obj.is_corrupt?(@jpg))
      assert_not(@obj.is_corrupt?(@png))
      assert_not(@obj.is_corrupt?(@webp))
      assert_not(@obj.is_corrupt?(@gif))
      assert_not(@obj.is_corrupt?(@mp4))
      assert_not(@obj.is_corrupt?(@webm))
      assert(@obj.is_corrupt?(@tiff))
      assert(@obj.is_corrupt?(@empty))
      assert(@obj.is_corrupt?(@corrupted))
    end
  end

  context "is_ai_generated?" do
    should "work" do
      assert_not(@obj.is_ai_generated?(@jpg))
      assert_not(@obj.is_ai_generated?(@png))
      assert_not(@obj.is_ai_generated?(@webp))
      assert_not(@obj.is_ai_generated?(@gif))
      assert_not(@obj.is_ai_generated?(@mp4))
      assert_not(@obj.is_ai_generated?(@webm))
      assert_not(@obj.is_ai_generated?(@tiff))
      assert_not(@obj.is_ai_generated?(@empty))
      # TODO: add ai generated image to test
    end
  end

  context "pixel_hash" do
    should "work for images" do
      assert_equal("01cb481ec7730b7cfced57ffa5abd196", @obj.pixel_hash(@jpg))
      assert_equal("d351db38efb2697d355cf89853099539", @obj.pixel_hash(@png))
      assert_equal("39225408c7673a19a5c69f596c0d1032", @obj.pixel_hash(@webp))
      assert_equal("516e3ef761c48e70036fb7cba973bb99", @obj.pixel_hash(@gif))
    end

    should "not work for videos" do
      assert_nil(@obj.pixel_hash(@apng))
      assert_nil(@obj.pixel_hash(@mp4))
      assert_nil(@obj.pixel_hash(@webm))
    end

    should "not work for invalid files" do
      assert_nil(@obj.pixel_hash(@tiff))
      assert_nil(@obj.pixel_hash(@empty))
    end
  end

  context "md5" do
    should "work" do
      assert_equal("ecef68c44edb8a0d6a3070b5f8e8ee76", @obj.md5(@jpg))
      assert_equal("081a5c3b92d8980d1aadbd215bfac5b9", @obj.md5(@png))
      assert_equal("291654feb88606970e927f32b08e2621", @obj.md5(@webp))
      assert_equal("05f1c7a0466a4e6a2af1eef3387f4dbe", @obj.md5(@gif))
      assert_equal("df87217e2c181ae6674898dff27e5a56", @obj.md5(@tiff))
      assert_equal("d41d8cd98f00b204e9800998ecf8427e", @obj.md5(@empty))
      assert_equal("865c93102cad3e8a893d6aac6b51b0d2", @obj.md5(@mp4))
      assert_equal("34dd2489f7aaa9e57eda1b996ff26ff7", @obj.md5(@webm))
    end
  end
end
