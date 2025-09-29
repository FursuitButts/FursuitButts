# frozen_string_literal: true

class DestroyedPost < ApplicationRecord
  belongs_to_user(:destroyer, ip: true, clones: :updater)
  belongs_to_user(:uploader, ip: true, optional: true)
  resolvable(:updater)
  after_update(:log_notify_change, if: :saved_change_to_notify?)

  def log_notify_change
    action = notify? ? :enable_post_notifications : :disable_post_notifications
    StaffAuditLog.log!(updater, action, destroyed_post_id: id, post_id: post_id)
  end

  module SearchMethods
    def query_dsl
      super
        .field(:post_id)
        .field(:md5)
        .field(:notify)
        .field(:reason_matches, :reason)
        .field(:destroyer_ip_addr)
        .field(:uploader_ip_addr)
        .association(:destroyer)
        .association(:uploader)
    end
  end

  extend(SearchMethods)

  def notify_reupload(uploader, replacement_post_id: nil)
    return if notify == false
    reason = "User tried to re-upload \"previously destroyed post ##{post_id}\":/admin/destroyed_posts/#{post_id}"
    reason += " as a replacement for post ##{replacement_post_id}" if replacement_post_id.present?
    Ticket.create!(
      creator_id:      User.system.id,
      creator_ip_addr: "127.0.0.1",
      status:          "pending",
      model:           uploader,
      reason:          reason,
    ).push_pubsub("create")
  end

  def self.available_includes
    %i[destroyer uploader]
  end

  def visible?(user)
    user.is_admin?
  end
end
