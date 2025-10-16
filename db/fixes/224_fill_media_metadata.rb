#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

[UploadMediaAsset, PostReplacementMediaAsset, MascotMediaAsset].each do |model|
  model.transaction do
    model.find_each do |record|
      puts("#{model.name}:#{record.id}")
      record.load_file!
      # use backup storage manager, prevent needing to pull down every remote file in prod
      if Rails.env.production?
        record.file = File.open(record.backup_storage_manager.file_path(record.md5, record.file_ext, :original, protected: record.is_protected?, prefix: record.path_prefix, protected_prefix: record.protected_path_prefix, hierarchical: record.hierarchical?))
      end
      record.reset_file_attributes!
    rescue Errno::ENOENT
      puts("Missing file for #{model.name}:#{record.id}")
    end
  end
end
