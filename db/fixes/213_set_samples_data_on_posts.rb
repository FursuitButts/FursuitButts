#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))

def handle_rescales(post, rescales, video)
  data = []
  rescales.each do |size, dims|
    next if post.image_width <= dims[0] && post.image_height <= dims[1]
    width, height = post.scaled_sample_dimensions(dims)
    if video
      webm_file = File.open(post.storage_manager.file_path(post.md5, "webm", :scaled, protected: post.is_deleted?, scale_factor: size))
      mp4_file = File.open(post.storage_manager.file_path(post.md5, "mp4", :scaled, protected: post.is_deleted?, scale_factor: size))
      data << { type: size, width: width, height: height, size: webm_file.size, md5: Digest::MD5.file(webm_file.path).hexdigest, ext: "webm", video: true } if webm_file.present?
      data << { type: size, width: width, height: height, size: mp4_file.size, md5: Digest::MD5.file(mp4_file.path).hexdigest, ext: "mp4", video: true } if mp4_file.present?
    else
      file = File.open(post.storage_manager.file_path(post.md5, post.file_ext, :scaled, protected: post.is_deleted?, scale_factor: size))
      data << { type: size, width: width, height: height, size: file.size, md5: Digest::MD5.file(file.path).hexdigest, ext: post.file_ext, video: false }
    end
  end
  data
end

Post.find_in_batches(batch_size: 10_000) do |posts|
  posts.each do |post|
    puts post.id
    data = []
    [
      ["preview", (post.has_preview? && File.open(post.preview_file_path)) || nil],
      ["crop", (post.has_cropped? && File.open(post.crop_file_path)) || nil],
      ["large", (post.has_large? && File.open(post.large_file_path)) || nil],
    ].reject { |s| s.second.nil? }.each do |(type, file)|
      width, height = UploadService::Utils.calculate_dimensions(file.path)
      data << { type: type, width: width, height: height, size: file.size, md5: Digest::MD5.file(file.path).hexdigest, ext: UploadService::Utils.file_header_to_file_ext(file.path), video: false }
    end

    # This isn't *really* properly implemented, but I'm including it anyways
    data += handle_rescales(post, FemboyFans.config.image_rescales, false)

    if post.is_video?
      ext = post.is_webm? ? "mp4" : "webm"
      original = File.open(post.storage_manager.file_path(post.md5, ext, :original, protected: post.is_deleted?))
      data << { type: "original", width: post.image_width, height: post.image_height, size: original.size, md5: Digest::MD5.file(original.path).hexdigest, ext: ext, video: true }
      data += handle_rescales(post, FemboyFans.config.video_rescales, true)
    end

    post.update_columns(samples_data: data)
  end
end
