#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))

DIR = "/app/public/data/replacements"
def file_path(md5, file_ext)
  "#{DIR}/#{md5[0..1]}/#{md5[2..3]}/#{md5}.#{file_ext}"
end

def handle(post_replacement)
  puts(post_replacement.id)
  asset = PostReplacementMediaAsset.new(file: File.open(file_path(post_replacement.storage_id_in_database, post_replacement.file_ext_in_database)), creator_id: post_replacement.creator_id, creator_ip_addr: post_replacement.creator_ip_addr, checksum: post_replacement.md5_in_database, storage_id: post_replacement.storage_id_in_database)
  asset.save!
  asset.set_file_attributes
  asset.status = "active"
  asset.save!
  post_replacement.update_columns(post_replacement_media_asset_id: asset.id)
  asset.regenerate_variants # we do need to regenerate the thumbnail
rescue StandardError => e
  puts("#{post_replacement.id}: #{e.message}")
end

PostReplacementMediaAsset.in_progress.delete_all
PostReplacement.where(post_replacement_media_asset_id: nil).find_each { |post_replacement| handle(post_replacement) }
