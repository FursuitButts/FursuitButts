#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))

DIR = "/app/public/data/mascots"
def file_path(md5, file_ext)
  "#{DIR}/#{md5}.#{file_ext}"
end

def handle(mascot)
  puts(mascot.id)
  # neither the mascot nor the mod action store the ip address of the creator
  # we have to use _in_database due to the bare names being delegated
  asset = MascotMediaAsset.new(file: File.open(file_path(mascot.md5_in_database, mascot.file_ext_in_database)), creator_id: mascot.creator_id, creator_ip_addr: "127.0.0.1")
  asset.save!
  asset.set_file_attributes
  asset.status = "active"
  asset.save!
  mascot.update_columns(mascot_media_asset_id: asset.id)
rescue StandardError => e
  puts("#{mascot.id}: #{e.message}")
end

MascotMediaAsset.in_progress.delete_all
Mascot.where(mascot_media_asset_id: nil).find_each { |mascot| handle(mascot) }
