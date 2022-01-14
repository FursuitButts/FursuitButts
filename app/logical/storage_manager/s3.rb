class StorageManager::S3 < StorageManager
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/S3/Client.html#put_object-instance_method
  DEFAULT_PUT_OPTIONS = {
    acl: "public-read",
    storage_class: "STANDARD",
    cache_control: "public, max-age=#{1.year.to_i}"
  }

  attr_reader :bucket, :client, :s3_options

  def initialize(bucket, client: nil, s3_options: {}, **options)
    @bucket = bucket
    @client = client || Aws::S3::Client.new(**s3_options)
    super(**options)
  end

  def key(path)
    path.sub(/^.+?data\//, "")
  end

  def store(io, path)
    if Danbooru.config.replacement_path_prefix.in? path
      bucket = Danbooru.config.s3_protected_bucket
    end
    data = io.read
    base64_md5 = Digest::MD5.base64digest(data)
    client.put_object(bucket: bucket, key: key(path), body: data, content_md5: base64_md5, **DEFAULT_PUT_OPTIONS)
  end

  def delete(path)
    if Danbooru.config.replacement_path_prefix.in? path
      bucket = Danbooru.config.s3_protected_bucket
    end
    @client.delete_object(bucket: bucket, key: key(path))
  rescue Aws::S3::Errors::NoSuchKey
    # ignore
  end

  def open(path)
    if Danbooru.config.replacement_path_prefix.in? path
      bucket = Danbooru.config.s3_protected_bucket
    end
    file = Tempfile.new(binmode: true)
    @client.get_object(bucket: bucket, key: key(path), response_target: file)
    file
  end

  def move_file_delete(post)
    IMAGE_TYPES.each do |type|
      key = key(file_path(post, post.file_ext, type, false))
      new_key = key(file_path(post, post.file_ext, type, true))
      client.copy_object(bucket: Danbooru.config.s3_protected_bucket, copy_source: "#{Danbooru.config.s3_bucket}/#{key}", key: new_key)
      client.delete_object(bucket: Danbooru.config.s3_bucket, key: key)
    end
    return unless post.is_video?
    Danbooru.config.video_rescales.each do |k,v|
      ['mp4','webm'].each do |ext|
        key = key(file_path(post, ext, :scaled, false, scale_factor: k.to_s))
        new_key = key(file_path(post, ext, :scaled, true, scale_factor: k.to_s))
        client.copy_object(bucket: Danbooru.config.s3_protected_bucket, copy_source: "#{Danbooru.config.s3_bucket}/#{key}", key: new_key)
        client.delete_object(bucket: Danbooru.config.s3_bucket, key: key)
      end
    end
    key = key(file_path(post, 'mp4', :original, false))
    new_key = key(file_path(post, 'mp4', :original, true))
    client.copy_object(bucket: Danbooru.config.s3_protected_bucket, copy_source: "#{Danbooru.config.s3_bucket}/#{key}", key: new_key)
    client.delete_object(bucket: Danbooru.config.s3_bucket, key: key)
  end

  def move_file_undelete(post)
    IMAGE_TYPES.each do |type|
      key = key(file_path(post, post.file_ext, type, true))
      new_key = key(file_path(post, post.file_ext, type, false))
      client.copy_object(bucket: Danbooru.config.s3_bucket, copy_source: "#{Danbooru.config.s3_protected_bucket}/#{key}", key: new_key)
      client.delete_object(bucket: Danbooru.config.s3_protected_bucket, key: key)
    end
    return unless post.is_video?
    Danbooru.config.video_rescales.each do |k,v|
      ['mp4','webm'].each do |ext|
        key = key(file_path(post, ext, :scaled, true, scale_factor: k.to_s))
        new_key = key(file_path(post, ext, :scaled, false, scale_factor: k.to_s))
        client.copy_object(bucket: Danbooru.config.s3_bucket, copy_source: "#{Danbooru.config.s3_protected_bucket}/#{key}", key: new_key)
        client.delete_object(bucket: Danbooru.config.s3_protected_bucket, key: key)
      end
    end
    key = key(file_path(post, 'mp4', :original, true))
    new_key = key(file_path(post, 'mp4', :original, false))
    client.copy_object(bucket: Danbooru.config.s3_bucket, copy_source: "#{Danbooru.config.s3_protected_bucket}/#{key}", key: new_key)
    client.delete_object(bucket: Danbooru.config.s3_protected_bucket, key: key)
  end

  def move_file_replacement(post, replacement, direction)
    if direction == :to_replacement
      key = key(file_path(post, post.file_ext, :original))
      new_key = key(replacement_path(replacement, replacement.file_ext))
      client.copy_object(bucket: Danbooru.config.s3_protected_bucket, copy_source: "#{Danbooru.config.s3_protected_bucket}/#{key}", key: new_key)
      client.delete_object(bucket: Danbooru.config.s3_bucket, key: key)
    else
      key = replacement_path(replacement, replacement.file_ext)
      new_key = file_path(post, post.file_ext, :original)
      client.copy_object(bucket: Danbooru.config.s3_protected_bucket, copy_source: "#{Danbooru.config.s3_bucket}/#{key}", key: new_key)
      client.delete_object(bucket: Danbooru.config.s3_bucket, key: key)
    end
  end
end
