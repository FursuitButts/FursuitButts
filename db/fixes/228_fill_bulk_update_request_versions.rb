#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

BulkUpdateRequest.find_each do |bur|
  puts(bur.id)
  bur.create_version
end
