#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))

[BulkUpdateRequest, TagAlias, TagImplication].each do |klass|
  klass.find_each do |tcr|
    puts "#{tcr.class.name}: #{tcr.id}"
    if tcr.forum_post.present? && tcr.forum_post.tag_change_request != tcr
      forum_post.update(tag_change_request: tcr)
    end
  end
end
