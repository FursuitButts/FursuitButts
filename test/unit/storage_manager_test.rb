# frozen_string_literal: true

require "test_helper"

class StorageManagerTest < ActiveSupport::TestCase
  BASE_DIR = Rails.root.join("tmp/test-storage").to_s

  context "StorageManager::Local" do
    setup do
      @storage_manager = StorageManager::Local.new(base_dir: BASE_DIR, base_url: "/")
    end

    teardown do
      FileUtils.rm_rf(BASE_DIR)
    end

    context "#store method" do
      should "store the file" do
        @storage_manager.store(StringIO.new("data"), "#{BASE_DIR}/test.txt")

        assert("data", File.read("#{BASE_DIR}/test.txt"))
      end

      should "overwrite the file if it already exists" do
        @storage_manager.store(StringIO.new("foo"), "#{BASE_DIR}/test.txt")
        @storage_manager.store(StringIO.new("bar"), "#{BASE_DIR}/test.txt")

        assert("bar", File.read("#{BASE_DIR}/test.txt"))
      end
    end

    context "#delete method" do
      should "delete the file" do
        @storage_manager.store(StringIO.new("data"), "test.txt")
        @storage_manager.delete("test.txt")

        assert_not(File.exist?("#{BASE_DIR}/test.txt"))
      end

      should "not fail if the file doesn't exist" do
        assert_nothing_raised { @storage_manager.delete("dne.txt") }
      end
    end

    context "#store_file and #delete_file methods" do
      setup do
        @post = create(:post, file_ext: "png")

        @storage_manager.store_file(StringIO.new("data"), @post, :preview)
        @storage_manager.store_file(StringIO.new("data"), @post, :large)
        @storage_manager.store_file(StringIO.new("data"), @post, :original)

        @file_path = "#{BASE_DIR}/preview/#{@post.md5}.webp"
        @large_file_path = "#{BASE_DIR}/sample/#{@post.md5}.webp"
        @preview_file_path = "#{BASE_DIR}/#{@post.md5}.#{@post.file_ext}"
      end

      should "store the files at the correct path" do
        assert(File.exist?(@file_path))
        assert(File.exist?(@large_file_path))
        assert(File.exist?(@preview_file_path))
      end

      should "delete the files" do
        @storage_manager.delete_file(@post.id, @post.md5, @post.file_ext, :preview)
        @storage_manager.delete_file(@post.id, @post.md5, @post.file_ext, :large)
        @storage_manager.delete_file(@post.id, @post.md5, @post.file_ext, :original)

        assert_not(File.exist?(@file_path))
        assert_not(File.exist?(@large_file_path))
        assert_not(File.exist?(@preview_file_path))
      end
    end

    context "#file_url method" do
      should "return the correct urls" do
        @post = create(:post, file_ext: "png")

        assert_equal("/data/#{@post.md5}.png", @storage_manager.file_url(@post, :original))
        assert_equal("/data/sample/#{@post.md5}.webp", @storage_manager.file_url(@post, :large))
        assert_equal("/data/preview/#{@post.md5}.webp", @storage_manager.file_url(@post, :preview))
      end
    end
  end
end
