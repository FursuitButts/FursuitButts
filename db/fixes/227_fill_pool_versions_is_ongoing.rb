#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

Pool.find_each do |pool|
  pool.update_columns(is_ongoing: true)
  puts("Pool:#{pool.id}")
end

PoolVersion.where(version: 1).find_each do |pool_version|
  pool_version.update_columns(is_ongoing: true, is_ongoing_changed: true)
  puts("PoolVersion:#{pool_version.id}")
end
