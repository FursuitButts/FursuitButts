# frozen_string_literal: true

require "net/ftp"

module StorageManager
  class Ftp < StorageManager::Base
    TEMP_DIR = "/tmp"
    attr_reader :host, :port, :username, :password

    def initialize(host:, port:, username:, password:, **options)
      @host = host
      @port = port
      @username = username
      @password = password
      super(**options)
    end

    def open_ftp
      ftp = Net::FTP.open(host, {
        port:     port,
        username: username,
        password: password,
      })
      if block_given?
        begin
          yield(ftp)
        ensure
          ftp.close
        end
      else
        ftp
      end
    end

    def store(io, dest_path)
      temp_path = "#{TEMP_DIR}#{dest_path}-#{SecureRandom.uuid}.tmp"

      FileUtils.mkdir_p(File.dirname(temp_path))
      io.rewind
      bytes_copied = IO.copy_stream(io, temp_path)
      raise(Error, "store failed: #{bytes_copied}/#{io.size} bytes copied") if bytes_copied != io.size

      open_ftp do |ftp|
        ftp.putbinaryfile(temp_path, dest_path)
      end
    rescue StandardError => e
      FileUtils.rm_f(temp_path)
      raise(Error, e)
    ensure
      FileUtils.rm_f(temp_path) if temp_path
    end

    def delete(path)
      open_ftp do |ftp|
        ignore_notfound { ftp.delete(path) }
      end
    end

    def open(path, &)
      file = Tempfile.new(binmode: true)
      open_ftp do |ftp|
        ftp.getbinaryfile(path, file)
      end
      if block_given?
        begin
          yield(file)
        ensure
          file.close
        end
      else
        file
      end
    end

    def move_file_delete(post)
      StorageManager::IMAGE_TYPES.each do |type|
        path = file_path(post, post.file_ext, type, protected: false)
        new_path = file_path(post, post.file_ext, type, protected: true)
        move_file(path, new_path)
      end

      FemboyFans.config.image_rescales.each_key do |k|
        path = file_path(post, "webp", :scaled, protected: false, scale_factor: k.to_s)
        new_path = file_path(post, "webp", :scaled, protected: true, scale_factor: k.to_s)
        move_file(path, new_path)
      end

      return unless post.is_video?
      FemboyFans.config.video_rescales.each do |k|
        Post::VIDEO_EXTENSIONS.each do |ext|
          path = file_path(post, ext, :scaled, scale_factor: k.to_s, protected: false)
          new_path = file_path(post, ext, :scaled, protected: true, scale_factor: k.to_s)
          move_file(path, new_path)
        end
      end
      path = file_path(post, post.is_webm? ? "mp4" : "webm", :original, protected: false)
      new_path = file_path(post, post.is_webm? ? "mp4" : "webm", :original, protected: true)
      move_file(path, new_path)
    end

    def move_file_undelete(post)
      StorageManager::IMAGE_TYPES.each do |type|
        path = file_path(post, post.file_ext, type, protected: true)
        new_path = file_path(post, post.file_ext, type, protected: false)
        move_file(path, new_path)
      end

      FemboyFans.config.image_rescales.each_key do |k|
        path = file_path(post, "webp", :scaled, protected: true, scale_factor: k.to_s)
        new_path = file_path(post, "webp", :scaled, protected: false, scale_factor: k.to_s)
        move_file(path, new_path)
      end

      return unless post.is_video?
      FemboyFans.config.video_rescales.each do |k|
        Post::VIDEO_EXTENSIONS.each do |ext|
          path = file_path(post, ext, :scaled, protected: true, scale_factor: k.to_s)
          new_path = file_path(post, ext, :scaled, protected: false, scale_factor: k.to_s)
          move_file(path, new_path)
        end
      end

      path = file_path(post, post.is_webm? ? "mp4" : "webm", :original, protected: true)
      new_path = file_path(post, post.is_webm? ? "mp4" : "webm", :original, protected: false)
      move_file(path, new_path)
    end

    private

    def move_file(old_path, new_path)
      store(self.open(old_path), new_path)
      delete(old_path)
    end

    def ignore_notfound
      yield
    rescue Net::FTPPermError => e
      raise(e) unless e.message =~ /550/
    end
  end
end
