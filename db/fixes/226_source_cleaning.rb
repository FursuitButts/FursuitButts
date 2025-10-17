#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

updater = User.system.resolable("127.0.0.1")
Post.without_timeout do
  fixed = 0
  Post.in_batches(load: true, order: :desc).each_with_index do |group, index|
    group.each do |post|
      puts post.id
      post.strip_source
      if post.changed?
        post.updater = updater
        post.save(validate: false)
        fixed += 1
      end
    end

    puts("batch #{index} fixed #{fixed}")
  end
end
