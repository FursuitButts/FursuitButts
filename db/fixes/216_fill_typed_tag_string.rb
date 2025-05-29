#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

Post.find_in_batches(batch_size: 1_000) do |posts|
  tags = Tag.where(name: posts.map(&:tag_array).flatten.uniq).select(:name, :category)
  posts.each do |post|
    typed = tags.select { |t| post.tag_array.include?(t.name) }.map { |t| "#{t.category}|#{t.name}" }.join(" ")
    puts(post.id)
    post.update_columns(typed_tag_string: typed)
  end
end
