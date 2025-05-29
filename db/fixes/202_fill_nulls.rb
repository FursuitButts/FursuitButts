#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

system = User.system
Comment.where(updater_ip_addr: nil).update_all(creator_ip_addr: "0.0.0.0")
Comment.where(updater_id: nil).update_all("updater_id = creator_id")
ForumPost.where(creator_ip_addr: nil).update_all(creator_ip_addr: "0.0.0.0")
PoolVersion.where(updater_id: nil).update_all(updater_id: system.id)
PoolVersion.where(updater_ip_addr: nil).update_all(updater_ip_addr: "0.0.0.0")
PostVersion.where(updater_id: nil).update_all(updater_id: system.id)
PostVote.where(user_ip_addr: nil).update_all(user_ip_addr: "0.0.0.0")
UserFeedback.where(creator_ip_addr: nil).update_all(creator_ip_addr: "0.0.0.0")
UserFeedback.where(updater_id: nil).update_all("updater_id = creator_id")
WikiPage.where(updater_id: nil).update_all(updater_id: system.id)
