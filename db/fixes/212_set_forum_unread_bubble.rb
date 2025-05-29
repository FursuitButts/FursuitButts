#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

User.find_each do |user|
  puts(user.id)
  user.update(forum_unread_bubble: true)
end
