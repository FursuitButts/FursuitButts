# frozen_string_literal: true

module FileMethods
  extend(ActiveSupport::Concern)
  VIDEO_EXTENSIONS = %w[webm mp4].freeze
  IMAGE_EXTENSIONS = %w[png jpg gif webp].freeze
  EXTENSIONS = (IMAGE_EXTENSIONS + VIDEO_EXTENSIONS).freeze

  module ClassMethods
    def file_header_to_file_ext(file_path)
      File.open(file_path) do |bin|
        mime_type = Marcel::MimeType.for(bin)
        case mime_type
        when "image/jpeg"
          "jpg"
        when "image/gif"
          "gif"
        when "image/png"
          "png"
        when "image/webp"
          "webp"
        when "video/webm"
          "webm"
        when "video/mp4"
          "mp4"
        else
          mime_type
        end
      end
    end

    EXTENSIONS.each do |ext|
      define_method("is_#{ext}?") { |file_ext| file_ext == ext }
      define_method("is_file_#{ext}?") { |file_path| send("is_#{ext}?", file_header_to_file_ext(file_path)) }
    end

    def video(file_path, ...)
      return unless is_file_video?(file_path)
      FFMPEG::Movie.new(file_path, ...)
    end

    def video_duration(file_path)
      video(file_path)&.duration
    end

    def video_framecount(file_path)
      video = self.video(file_path)
      return nil unless video&.duration && video.frame_rate
      (video.frame_rate * video.duration).ceil
    end

    def image(file_path, **)
      return unless is_file_image?(file_path)
      Vips::Image.new_from_file(file_path, **)
    end

    def calculate_dimensions(file_path)
      if is_file_image?(file_path) && (image = self.image(file_path))
        return [image.width, image.height]
      elsif is_file_video?(file_path) && (video = self.video(file_path))
        return [video.width, video.height]
      end
      [0, 0]
    end

    def is_image?(file_ext)
      IMAGE_EXTENSIONS.include?(file_ext)
    end

    def is_file_image?(file_path)
      is_image?(file_header_to_file_ext(file_path))
    end

    def is_video?(file_ext)
      VIDEO_EXTENSIONS.include?(file_ext)
    end

    def is_file_video?(file_path)
      is_video?(file_header_to_file_ext(file_path))
    end

    def is_valid_extension?(file_ext)
      EXTENSIONS.include?(file_ext)
    end

    def is_file_valid_extension?(file_path)
      is_valid_extension?(file_header_to_file_ext(file_path))
    end

    def is_animated_png?(file_path)
      return false unless is_file_png?(file_path)
      ApngInspector.new(file_path).inspect!.animated?
    end

    def is_animated_gif?(file_path)
      return false unless is_file_gif?(file_path)

      # Check whether the gif has multiple frames by trying to load the second frame.
      result = begin
        Vips::Image.gifload(file_path, page: 1)
      rescue StandardError
        $ERROR_INFO
      end
      if result.is_a?(Vips::Image)
        true
      elsif result.is_a?(Vips::Error) && result.message =~ /bad page number/
        false
      else
        raise(result)
      end
    end

    def is_corrupt?(file_path)
      return false if is_file_video?(file_path)
      image = self.image(file_path, fail: true)
      image.stats
      false
    rescue StandardError
      true
    end

    def is_ai_generated?(file_path)
      return false unless is_file_image?(file_path)

      image = self.image(file_path)
      fetch = ->(key) do
        value = image.get(key)
        value.encode("ASCII", invalid: :replace, undef: :replace).gsub("\u0000", "")
      rescue Vips::Error
        ""
      end

      return true if fetch.call("png-comment-0-parameters").present?
      return true if fetch.call("png-comment-0-Dream").present?
      return true if fetch.call("exif-ifd0-Software").include?("NovelAI") || fetch.call("png-comment-2-Software").include?("NovelAI")
      return true if ["exif-ifd0-ImageDescription", "exif-ifd2-UserComment", "png-comment-4-Comment"].any? { |field| fetch.call(field).include?('"sampler": "') }
      exif_data = fetch.call("exif-data")
      return true if ["Model hash", "OpenAI", "NovelAI"].any? { |marker| exif_data.include?(marker) }
      false
    end

    def pixel_hash(file_path)
      return unless is_file_image?(file_path) && !is_animated_png?(file_path)
      image = self.image(file_path)
      image = image.icc_transform("srgb") if image.get_typeof("icc-profile-data") != 0
      image = image.colourspace("srgb") if image.interpretation != :srgb
      image = image.add_alpha unless image.has_alpha?

      # PAM file format: https://netpbm.sourceforge.net/doc/pam.html
      output = Tempfile.new(%W[pixel-hash-#{SecureRandom.hex(4)}- .pam], binmode: true)
      output.puts("P7")
      output.puts("WIDTH #{image.width}")
      output.puts("HEIGHT #{image.height}")
      output.puts("DEPTH #{image.bands}")
      output.puts("MAXVAL 255")
      output.puts("TUPLTYPE RGB_ALPHA")
      output.puts("ENDHDR")
      output.flush
      image.rawsave_fd(output.fileno)
      hash = md5(output.path)
      output.close!
      hash
    end

    def md5(file_path)
      Digest::MD5.file(file_path).hexdigest
    end
  end

  included do
    def get_file(&)
      if block_given?
        return yield(Tempfile.new(binmode: true)) if respond_to?(:skip_files) && skip_files # used in tests
        return yield(file) if file
        open_file(&)
      else
        return Tempfile.new(binmode: true) if respond_to?(:skip_files) && skip_files # used in tests
        return file if file
        open_file
      end
    end

    EXTENSIONS.each do |ext|
      define_method("is_#{ext}?") { file_ext == ext }
      define_method("is_file_#{ext}?") { get_file { |file| self.class.send("is_file_#{ext}?", file.path) } }
    end

    def video(&)
      if block_given?
        get_file { |file| yield(self.class.video(file.path)) }
        return
      end
      self.class.video(get_file.path)
    end

    def video_duration
      return unless is_video?
      get_file { |file| self.class.video_duration(file.path) }
    end

    def video_framecount
      return unless is_video?
      get_file { |file| self.class.video_framecount(file.path) }
    end

    def image(&)
      if block_given?
        get_file { |file| yield(self.class.image(file.path)) }
        return
      end
      self.class.image(get_file.path)
    end

    def calculate_dimensions
      get_file { |file| self.class.calculate_dimensions(file.path) }
    end

    def is_image?
      self.class.is_image?(file_ext)
    end

    def is_file_image?
      get_file { |file| self.class.is_file_image?(file.path) }
    end

    def is_video?
      self.class.is_video?(file_ext)
    end

    def is_file_video?
      get_file { |file| self.class.is_file_video?(file.path) }
    end

    # def is_animated_png?
    #   is_png? && get_file { |file| self.class.is_animated_png?(file.path) }
    # rescue Errno::ENOENT
    #   false
    # end

    # def is_animated_gif?
    #   is_gif? && get_file { |file| self.class.is_animated_gif?(file.path) }
    # rescue Errno::ENOENT
    #   false
    # end

    def is_corrupt?
      get_file { |file| self.class.is_corrupt?(file.path) }
    end

    def is_ai_generated?
      get_file { |file| self.class.is_ai_generated?(file.path) }
    end

    def file_pixel_hash
      return unless is_image? && !is_animated_png?
      get_file { |file| self.class.pixel_hash(file.path) }
    end

    def file_md5
      get_file { |file| self.class.md5(file.path) }
    end
  end
end
