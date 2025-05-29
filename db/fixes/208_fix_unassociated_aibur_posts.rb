#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

[BulkUpdateRequest, TagAlias, TagImplication].each do |klass|
  klass.where.not(forum_post_id: nil).find_each do |tcr|
    puts("#{tcr.class.name}: #{tcr.id}")
    if tcr.forum_post.present? && tcr.forum_post.tag_change_request != tcr
      tcr.forum_post.update_columns(tag_change_request_id: tcr.id, tag_change_request_type: tcr.class.name)
    end
  end
end
