# frozen_string_literal: true

class Autotagger
  TAGS = [
    [%w[superabsurd_res],       ->(post) { post.image_width >= 10_000 && post.image_height >= 10_000 }],
    [%w[absurd_res],            ->(post) { post.image_width >= 3200 || post.image_height >= 2400 }],
    [%w[hi_res],                ->(post) { post.image_width >= 1600 || post.image_height >= 1200 }],
    [%w[low_res],               ->(post) { post.image_width <= 500 && post.image_height <= 2400 }],
    [%w[thumbnail],             ->(post) { post.image_width <= 250 && post.image_height <= 250 }],
    [%w[wide_image long_image], ->(post) { post.image_width >= 1024 && post.image_width.to_f / post.image_height >= 4 }],
    [%w[tall_image long_image], ->(post) { post.image_height >= 1024 && post.image_height.to_f / post.image_width >= 4 }],
    [%w[insane_filesize],       ->(post) { post.file_size >= 175.megabytes }],
    [%w[absurd_filesize],       ->(post) { post.file_size >= 125.megabytes }],
    [%w[huge_filesize],         ->(post) { post.file_size >= 75.megabytes }],
    [%w[large_filesize],        ->(post) { post.file_size >= 25.megabytes }],
    [%w[webm],                  ->(post) { post.is_webm? }],
    [%w[mp4],                   ->(post) { post.is_mp4? }],
    [%w[animated_webp],         ->(post) { post.is_animated_webp? }],
    [%w[animated_gif],          ->(post) { post.is_animated_gif? }],
    [%w[animated_png],          ->(post) { post.is_animated_png? }],
    [%w[long_playtime],         ->(post) { post.is_video? && post.duration >= 30 }],
    [%w[short_playtime],        ->(post) { post.is_video? && post.duration < 30 }],
    [%w[invalid_source],        ->(post) { post.invalid_source? }],
    [%w[bad_source],            ->(post) { post.bad_source? }],
  ].freeze

  attr_accessor(:post)

  def initialize(post)
    @post = post
  end

  def apply(tags)
    tags -= TAGS.flat_map(&:first)

    TAGS.each do |tagset, proc|
      tags += tagset if proc.call(post)
    end

    tags
  end
end
