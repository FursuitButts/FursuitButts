#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))

User.system.set_user

Pool.find_each do |pool|
  puts pool.id
  pool.update_cover_post
  pool.save
end
