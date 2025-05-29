#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

ForumCategory.find_each do |category|
  puts(category.id)
  category.update_columns(topic_count: category.topics.count, post_count: category.posts.count)
end
