#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

User.without_timeout do
  User.find_each do |user|
    user.update_columns(post_vote_count: user.post_votes.count, comment_vote_count: user.comment_votes.count, forum_post_vote_count: user.forum_post_votes.count)
  end
end
