#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "base"

posts = Post.joins(:uploader).where("users.level": User::Levels::SYSTEM)
total = posts.count
step = (total * 0.1).to_i
user_count = (total * 0.15).to_i
RANGE = 0 # ..10

users = User.where(level: User::Levels::MEMBER, post_count: RANGE).order("RANDOM()").limit(user_count).all

raise("Failed to find any users") if users.empty?

ApplicationRecord.transaction do
  posts.find_each.with_index do |post, i|
    puts "Reassigning posts.. #{i + 1}/#{total}" if (i + 1) % step == 0 || (i + 1) == total
    user = users.sample
    post.update_column(:uploader_id, user.id)
    post.versions.find_each do |version|
      version.update_column(:updater_id, user.id)
    end
    post.upload&.update_column(:uploader_id, user.id)
    post.media_asset.update_column(:creator_id, user.id)
    post.document_store.update_index
  end

  User.system.refresh_counts!
  users.each(&:refresh_counts!)
end
