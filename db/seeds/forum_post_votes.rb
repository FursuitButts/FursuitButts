#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))

# Note that too many votes on a single page will result in the topic being unusable
users = User.where(level: User::Levels::MEMBER, forum_post_vote_count: ..10).order("id asc").limit(50)

TOPIC = 2
IP_ADDR = "127.0.0.1"
votes = []
ForumTopic.find(TOPIC).posts.where(allow_voting: true).find_each do |post|
  users.each do |user|
    next if post.creator_id == user.id
    r = rand(1..100)
    score = if r.in?(1..65)
              1
            else
              r.in?(66..85) ? 0 : -1
            end
    votes << { user_id: user.id, user_ip_addr: IP_ADDR, score: score, forum_post_id: post.id }
  end
end

puts "Inserting #{votes.count} forum post votes..."
ForumPostVote.insert_all(votes)
puts "Done"
