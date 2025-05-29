#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

ForumPost.where.not(tag_change_request: nil).update_all("allow_voting = true")
