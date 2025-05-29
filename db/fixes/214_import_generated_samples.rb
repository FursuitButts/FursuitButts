#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

Post.find_each do |post|
  puts(post.id)
  data = post.samples_data
  post.samples_data = []
  post.update_samples_data(data) # Force reprocessing, additionally setting generated_samples
end
