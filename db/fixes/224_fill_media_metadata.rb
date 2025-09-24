#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

[UploadMediaAsset, PostReplacementMediaAsset, MascotMediaAsset].each do |model|
  model.find_each do |record|
    puts("#{model.name}:#{record.id}")
    record.load_file!
    record.set_file_attributes
    record.save
  rescue Errno::ENOENT
    puts("Missing file for #{model.name}:#{record.id}")
  end
end
