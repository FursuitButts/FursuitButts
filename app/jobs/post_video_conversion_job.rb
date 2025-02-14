# frozen_string_literal: true

class PostVideoConversionJob < ApplicationJob
  queue_as :samples
  sidekiq_options lock: :until_executed, lock_args_method: :lock_args, retry: 3

  def self.lock_args(args)
    [args[0]]
  end

  def perform(id)
    Post.transaction do
      post = Post.find(id)
      unless post.is_video?
        logger.info("Exiting as not a video")
        next
      end
      file = post.file
      samples, data = generate_video_samples(post, file)
      post.reload # Needed to prevent moving files into undeleted folder if the post is deleted while samples are being generated.
      move_videos(post, samples)
      post.reload
      post.update_samples_data(data)
    end
  ensure
    file.close!
  end

  def move_videos(post, samples)
    md5 = post.md5
    sm = FemboyFans.config.storage_manager
    samples.each do |name, named_samples|
      next if name.to_s == "original"
      webm_path = sm.file_path(md5, "webm", :scaled, protected: post.is_deleted?, scale_factor: name.to_s)
      sm.store(named_samples[0], webm_path)
      named_samples[0].close!
      mp4_path = sm.file_path(md5, "mp4", :scaled, protected: post.is_deleted?, scale_factor: name.to_s)
      sm.store(named_samples[1], mp4_path)
      named_samples[1].close!
    end
    sm.store(samples[:original][1], sm.file_path(md5, post.is_webm? ? "mp4" : "webm", :original, protected: post.is_deleted?))
    samples[:original].each(&:close!)
  end

  def generate_video_samples(post, file)
    outputs = {}
    data = []
    FemboyFans.config.video_rescales.each do |size, dims|
      next if post.image_width <= dims[0] && post.image_height <= dims[1]
      width, height = scaled_dims = post.scaled_sample_dimensions(dims)
      webm_file, mp4_file = outputs[size] = generate_scaled_video(file.path, scaled_dims)
      data << { type: size, width: width, height: height, size: webm_file.size, md5: Digest::MD5.file(webm_file.path).hexdigest, ext: "webm", video: true } if webm_file.present?
      data << { type: size, width: width, height: height, size: mp4_file.size, md5: Digest::MD5.file(mp4_file.path).hexdigest, ext: "mp4", video: true } if mp4_file.present?
    end
    webm_file, mp4_file = outputs[:original] = generate_scaled_video(file.path, post.scaled_sample_dimensions([post.image_width, post.image_height]), format: post.is_webm? ? :mp4 : :webm)
    file = post.is_webm? ? webm_file : mp4_file
    data << { type: "original", width: post.image_width, height: post.image_height, size: file.size, md5: Digest::MD5.file(file.path).hexdigest, ext: post.is_webm? ? "mp4" : "webm", video: true }
    [outputs, data]
  end

  def generate_scaled_video(infile, dimensions, format: :both)
    target_size = "scale=w=#{dimensions[0]}:h=#{dimensions[1]}"
    webm_file = Tempfile.new(%w[video-sample .webm], binmode: true)
    mp4_file = Tempfile.new(%w[video-sample .mp4], binmode: true)
    webm_args = [
      "-c:v",
      "libvpx-vp9",
      "-pix_fmt",
      "yuv420p",
      "-deadline",
      "good",
      "-cpu-used",
      "5", # 4+ disable a bunch of rate estimation features, but seems to save reasonable CPU time without large quality drop
      "-auto-alt-ref",
      "0",
      "-qmin",
      "20",
      "-qmax",
      "42",
      "-crf",
      "35",
      "-b:v",
      "3M",
      "-vf",
      target_size,
      "-threads",
      "4",
      "-row-mt",
      "1",
      "-max_muxing_queue_size",
      "4096",
      "-slices",
      "8",
      "-c:a",
      "libopus",
      "-b:a",
      "96k",
      "-map_metadata",
      "-1",
      "-metadata",
      'title="femboy.fan_preview_quality_conversion,_visit_site_for_full_quality_download"',
      webm_file.path,
    ]
    mp4_args = [
      "-c:v",
      "libx264",
      "-pix_fmt",
      "yuv420p",
      "-profile:v",
      "main",
      "-preset",
      "fast",
      "-crf",
      "27",
      "-b:v",
      "3M",
      "-vf",
      target_size,
      "-threads",
      "4",
      "-max_muxing_queue_size",
      "4096",
      "-c:a",
      "aac",
      "-b:a",
      "128k",
      "-map_metadata",
      "-1",
      "-metadata",
      'title="femboy.fan_preview_quality_conversion,_visit_site_for_full_quality_download"',
      "-movflags",
      "+faststart",
      mp4_file.path,
    ]
    args = [
      # "-loglevel",
      # "0",
      "-y",
      "-i",
      infile,
    ]
    if format != :mp4
      args += webm_args
    end
    if format != :webm
      args += mp4_args
    end
    stdout, stderr, status = Open3.capture3(FemboyFans.config.ffmpeg_path, *args)

    unless status == 0
      logger.warn("[FFMPEG TRANSCODE STDOUT] #{stdout.chomp}")
      logger.warn("[FFMPEG TRANSCODE STDERR] #{stderr.chomp}")
      raise(StandardError, "unable to transcode files\n#{stdout.chomp}\n\n#{stderr.chomp}")
    end
    [webm_file, mp4_file]
  end
end
