# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to(:user)
  enum(:category, {
    default:             0,
    new_post:            1,
    dmail:               2,
    mention:             3,
    feedback_create:     10,
    feedback_update:     11,
    feedback_delete:     12,
    feedback_undelete:   13,
    feedback_destroy:    14,
    post_delete:         20,
    post_undelete:       21,
    post_approve:        22,
    post_unapprove:      23,
    appeal_accept:       30,
    appeal_reject:       31,
    replacement_approve: 40,
    replacement_reject:  41,
    replacement_promote: 42,
  })
  store_accessor(:data, %i[post_id tag_name dmail_id dmail_title mention_id mention_type topic_id topic_title record_id record_type post_appeal_id post_replacement_id])
  store_accessor(:data, %i[user_id], prefix: true)
  after_commit(:update_unread_count)

  def h
    Rails.application.routes.url_helpers
  end

  def message
    case category
    when "new_post"
      "New post in tag [[#{tag_name}]]: post ##{post_id}"
    when "dmail"
      "@#{User.id_to_name(data_user_id)} sent you a dmail titled \"#{dmail_title}\""
    when "mention"
      base = "@#{User.id_to_name(data_user_id)} mentioned you in #{mention_type.humanize} ##{mention_id}"
      case mention_type
      when "Comment"
        base += " on post ##{post_id}"
      when "ForumPost"
        base += " in topic ##{topic_id} titled \"#{topic_title}\""
      end
      base
    when "feedback_create", "feedback_update", "feedback_delete", "feedback_undelete", "feedback_destroy"
      val = category[9..]
      val += "e" unless val.ends_with?("e")
      "@#{User.id_to_name(data_user_id)} #{val}d a #{record_type} on your account: record ##{record_id}"
    when "post_delete", "post_undelete", "post_approve", "post_unapprove"
      "Your post ##{post_id} was #{category[5..]}d"
    when "appeal_accept", "appeal_reject"
      "Your appeal on post ##{post_appeal_id} was #{category[7..]}ed"
    when "replacement_approve", "replacement_reject", "replacement_promote"
      "Your replacement on post ##{post_replacement_id} was #{category[12..]}#{'e' unless category.ends_with?('e')}d"
    else
      "Unknown notification category: #{category}"
    end
  end

  def view_link
    case category
    when "new_post", "post_delete", "post_undelete", "post_approve", "post_unapprove"
      h.post_path(post_id, n: id)
    when "dmail"
      h.dmail_path(dmail_id, n: id)
    when "mention"
      case mention_type
      when "Comment"
        h.post_path(post_id, anchor: "comment-#{mention_id}", n: id)
      when "ForumPost"
        h.forum_topic_path(topic_id, anchor: "forum_post_#{mention_id}", n: id)
      end
    when "feedback_create", "feedback_update", "feedback_delete", "feedback_undelete"
      h.user_feedback_path(record_id, n: id)
    when "feedback_destroy"
      nil
    when "appeal_accept", "appeal_reject"
      h.post_appeals_path(search: { id: post_appeal_id }, n: id)
    when "replacement_approve", "replacement_reject", "replacement_promote"
      h.post_replacements_path(search: { id: post_replacement_id }, n: id)
    else
      "#"
    end
  end

  def update_unread_count
    user.update!(unread_notification_count: user.notifications.unread.count)
  end

  def mark_as_read!
    update_column(:is_read, true)
    update_unread_count

    if dmail_id.present?
      Dmail.find_by(id: dmail_id, is_read: false).try(:mark_as_read!)
    end
  end

  def mark_as_unread!
    update_column(:is_read, false)
    update_unread_count
  end

  module SearchMethods
    def unread
      where(is_read: false)
    end

    def read
      where(is_read: true)
    end

    def for_user(user_id)
      where(user_id: user_id)
    end

    def search(params)
      q = super
      q = q.attribute_matches(:category, Notification.categories.fetch(params[:category], params[:category]).to_s) if params[:category].present?
      if params[:order].present?
        q = q.apply_basic_order(params)
      else
        q = q.order(:is_read, id: :desc)
      end
      q
    end
  end

  extend(SearchMethods)

  def self.available_includes
    %i[user]
  end

  def visible?(user = CurrentUser.user)
    user.id == user_id
  end
end
