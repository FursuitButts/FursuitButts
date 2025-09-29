#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

user = User.system

Pool.find_each do |pool|
  puts(pool.id)
  pool.updater = user
  pool.update_cover_post
  pool.save
end
