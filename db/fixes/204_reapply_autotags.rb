#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

CurrentUser.as_system do
  Post.find_each do |post|
    puts(post.id)
    post.tag_string += " "
    post.save!
  end
end
