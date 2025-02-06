# frozen_string_literal: true

module PostThumbnailer
  class CorruptFileError < RuntimeError; end
  module_function

  def generate_resizes(file, height, width, type, frame:)
    sample_data = []
    scaled = {}
    if type == :video
      video = FFMPEG::Movie.new(file.path)
      crop_file = generate_video_crop_for(video, FemboyFans.config.small_image_width, frame: frame)
      preview_file = generate_video_sample_for(file.path, width: FemboyFans.config.small_image_width, frame: frame)
      sample_file = generate_video_sample_for(file.path, frame: frame)

      FemboyFans.config.image_rescales.each do |size, (w, h)|
        next if width <= w && height <= h
        swidth, sheight = UploadService::Utils.scaled_sample_dimensions([w, h], width, height)
        sfile = generate_video_sample_for(file.path, width: swidth, frame: frame)
        next unless sfile.present?
        scaled[size] = sfile
        sample_data << { type: size, width: swidth, height: sheight, size: sfile.size, md5: Digest::MD5.file(sfile.path).hexdigest, ext: "webp", video: false }
      end
    elsif type == :image
      preview_file = FemboyFans::ImageResizer.resize(file, FemboyFans.config.small_image_width, FemboyFans.config.small_image_width, 87)
      crop_file = FemboyFans::ImageResizer.crop(file, FemboyFans.config.small_image_width, FemboyFans.config.small_image_width, 87)
      if width > FemboyFans.config.large_image_width
        sample_file = FemboyFans::ImageResizer.resize(file, FemboyFans.config.large_image_width, height, 87)
      end

      FemboyFans.config.image_rescales.each do |size, (w, h)|
        next if width <= w && height <= h
        swidth, sheight = UploadService::Utils.scaled_sample_dimensions([w, h], width, height)
        sfile = FemboyFans::ImageResizer.resize(file, swidth, sheight, 87)
        next unless sfile.present?
        scaled[size] = sfile
        sample_data << { type: size, width: swidth, height: sheight, size: sfile.size, md5: Digest::MD5.file(sfile.path).hexdigest, ext: "webp", video: false }
      end
    end

    [["preview", preview_file], ["crop", crop_file], ["large", sample_file]].reject { |s| s.second.blank? }.each do |(stype, sfile)|
      width, height = UploadService::Utils.calculate_dimensions(sfile.path)
      sample_data << { type: stype, width: width, height: height, size: sfile.size, md5: Digest::MD5.file(sfile.path).hexdigest, ext: UploadService::Utils.file_header_to_file_ext(sfile.path), video: false }
    end

    [preview_file, crop_file, sample_file, scaled, sample_data]
  end

  def generate_replacement_thumbnail(file, type, frame: nil)
    if type == :video
      preview_file = generate_video_sample_for(file.path, width: FemboyFans.config.replacement_thumbnail_width, frame: frame)
    elsif type == :image
      preview_file = FemboyFans::ImageResizer.resize(file, FemboyFans.config.replacement_thumbnail_width, FemboyFans.config.replacement_thumbnail_width, 87)
    end

    preview_file
  end

  def generate_video_crop_for(video, width, frame: nil)
    vp = Tempfile.new(%w[video-preview .webp], binmode: true)
    video.screenshot(vp.path, { resolution: "#{video.width}x#{video.height}", custom: (%W[-vf select=eq(n\\,#{frame - 1})] if frame.present? && frame != 0) })
    crop = FemboyFans::ImageResizer.crop(vp, width, width, 87)
    vp.close
    crop
  end

  def extract_frame_from_video(video, frame)
    output_file = Tempfile.new(%w[video-preview .webp], binmode: true)
    stdout, stderr, status = Open3.capture3(FemboyFans.config.ffmpeg_path, "-y", "-i", video, "-vf", "select=eq(n\\,#{frame - 1})", "-frames:v", "1", output_file.path)

    unless status == 0
      Rails.logger.warn("[FFMPEG FRAME STDOUT] #{stdout.chomp!}")
      Rails.logger.warn("[FFMPEG FRAME STDERR] #{stderr.chomp!}")
      raise(CorruptFileError, "could not extract frame")
    end
    output_file
  end

  def generate_video_sample_for(video, width: nil, frame: nil)
    output_file = Tempfile.new(%w[video-preview .webp], binmode: true)
    if frame.blank? || frame == 0
      opt = %W[-vf thumbnail]
    else
      opt = %W[-vf select=eq(n\\,#{frame - 1})]
    end
    if width
      o = opt.pop
      opt.push("#{o},scale=#{width}:-1")
    end
    stdout, stderr, status = Open3.capture3(FemboyFans.config.ffmpeg_path, "-y", "-i", video, *opt, "-frames:v", "1", output_file.path)

    unless status == 0
      Rails.logger.warn("[FFMPEG SAMPLE STDOUT] #{stdout.chomp!}")
      Rails.logger.warn("[FFMPEG SAMPLE STDERR] #{stderr.chomp!}")
      raise(CorruptFileError, "could not generate thumbnail")
    end
    output_file
  end
end
