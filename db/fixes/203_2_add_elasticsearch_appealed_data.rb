#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

client = Post.document_store.client
Post.find_each do |post|
  puts(post.id)
  client.update(index: Post.document_store.index_name, id: post.id, body: { doc: { appealed: post.is_appealed? } })
end
