#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

OLD_DIR = "/app/public/data"
NEW_DIR = "/app/public/data/posts"
def file_path(md5, file_ext, protected, old)
  "#{old ? OLD_DIR : NEW_DIR}#{'/deleted' if protected}/#{md5[0..1]}/#{md5[2..3]}/#{md5}.#{file_ext}"
end

def handle(post)
  puts(post.id)
  # move the file to the new location
  FileUtils.mkdir_p(File.dirname(file_path(post.md5_in_database, post.file_ext_in_database, post.protect_file?, false)))
  FileUtils.mv(file_path(post.md5_in_database, post.file_ext_in_database, post.protect_file?, true), file_path(post.md5_in_database, post.file_ext_in_database, post.protect_file?, false))
  # we have to use _in_database due to the bare names being delegated
  asset = UploadMediaAsset.new(file: File.open(file_path(post.md5_in_database, post.file_ext_in_database, post.protect_file?, false)), creator_id: post.uploader_id, creator_ip_addr: post.uploader_ip_addr, checksum: post.md5_in_database)
  asset.save!
  asset.set_file_attributes
  asset.status = post.protect_file? ? "deleted" : "active"
  asset.save!
  asset.regenerate_variants
  post.update_columns(upload_media_asset_id: asset.id)
  post.upload&.update_columns(upload_media_asset_id: asset.id)
rescue StandardError => e
  puts("#{post.id}: #{e.message}")
  puts(Rails.backtrace_cleaner.clean(e.backtrace))
end

FileUtils.mkdir_p(NEW_DIR)
UploadMediaAsset.in_progress.delete_all
Post.where(upload_media_asset_id: nil).where(file_ext: FileMethods::IMAGE_EXTENSIONS).find_each { |post| handle(post) }
Post.where(upload_media_asset_id: nil).where(file_ext: FileMethods::VIDEO_EXTENSIONS).find_each { |post| handle(post) }
