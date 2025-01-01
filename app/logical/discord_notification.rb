# frozen_string_literal: true

class DiscordNotification
  GREEN = 0x008000
  YELLOW = 0xFFA500
  RED = 0xFF0000

  attr_accessor :record

  def initialize(record)
    @record = record
  end

  def webhook_url
    FemboyFans.config.discord_webhook_url
  end

  def embed
    case record
    when Artist
      { color: GREEN, title: "Artist Created", description: "Name: #{record.name}", url: r.artist_url(record), author: a(record.creator) }
    when ArtistVersion
      return if record.version == 1
      { color: YELLOW, title: "Artist Edited", description: "Name: #{record.previous.try(:name) || record.name}", url: r.artist_version_url(record), author: a(record.updater) }
    when Ban
      { color: RED, title: "User Banned", description: "User: #{u(record.user)}", url: r.ban_url(record), author: a(record.banner) }
    when BulkUpdateRequest
      { color: GREEN, title: "Bulk Update Request Created", url: r.bulk_update_request_url(record), author: a(record.creator) }
    when Comment
      { color: GREEN, title: "Comment Created", url: r.comment_url(record), author: a(record.creator) }
    when CommentVote
      { color: GREEN, title: "Comment Vote Created", url: r.url_for(controller: "comments/votes", action: "index", search: { id: record.id }), author: a(record.user) }
    when EditHistory
      return if record.version == 1
      { color: YELLOW, title: "#{versionable_type.titleize} Edited", description: "Type: #{record.edit_type}", url: r.edit_history_url(id: record.versionable_id, type: record.versionable_type), author: a(record.updater) }
    when Favorite
      { color: GREEN, title: "Favorite Created", url: r.favorite_url(record), author: a(record.user) }
    when ForumPost
      return if record == record.topic.original_post
      { color: GREEN, title: "Forum Post Created", description: "Topic: [#{record.topic.title}](#{r.forum_topic_url(record.topic)})\nCategory: [#{record.category.name}](#{r.forum_category_url(record.category)})", url: r.forum_post_url(record), author: a(record.creator) }
    when ForumPostVote
      { color: GREEN, title: "Forum Post Vote Created", url: r.url_for(controller: "forums/posts/votes", action: "index", search: { id: record.id }), author: a(record.user) }
    when ForumTopic
      { color: GREEN, title: "Forum Topic Created", description: "Category: [#{record.category.name}](#{r.forum_category_url(record.category)})", url: r.forum_topic_url(record), author: a(record.creator) }
    when Note
      { color: GREEN, title: "Note Created", url: r.note_url(record), author: a(record.creator) }
    when NoteVersion
      return if record.version == 1
      { color: YELLOW, title: "Note Edited", url: r.note_version_url(record), author: a(record.updater) }
    when Pool
      { color: GREEN, title: "Pool Created", url: r.pool_url(record), author: a(record.creator) }
    when PoolVersion
      return if record.version == 1
      { color: YELLOW, title: "Pool Edited", url: r.pool_version_url(record), author: a(record.updater) }
    when Post
      { color: GREEN, title: "Post Created", url: r.post_url(record), author: a(record.creator) }
    when PostAppeal
      { color: GREEN, title: "Post Appeal Created", url: r.post_appeals_url(search: { id: record.id }), author: a(record.creator) }
    when PostEvent
      { color: GREEN, title: "Post Event Created", description: "Type: #{r.action}", url: r.post_events_url(search: { id: record.id }), author: a(record.creator) }
    when PostFlag
      { color: RED, title: "Post Flag Created", url: r.post_flags_url(search: { id: record.id }), author: a(record.creator) }
    when PostReplacement
      { color: GREEN, title: "Post Replacement Created", url: r.post_replacements_url(search: { id: record.id }), author: a(record.creator) }
    when PostSet
      { color: GREEN, title: "Post Set Created", url: r.post_set_url(record), author: a(record.creator) }
    when PostVersion
      return if record.version == 1
      { color: YELLOW, title: "Post Edited", url: r.post_version_url(record), author: a(record.updater) }
    when PostVote
      { color: GREEN, title: "Post Vote Created", url: r.url_for(controller: "posts/votes", action: "index", search: { id: record.id }), author: a(record.user) }
    when TagAlias
      { color: GREEN, title: "Tag Alias Created", description: "Antecedent: #{record.antecedent_name}\nConsequent: #{record.consequent_name}", url: r.tag_alias_url(record), author: a(record.creator) }
    when TagImplication
      { color: GREEN, title: "Tag Implication Created", description: "Antecedent: #{record.antecedent_name}\nConsequent: #{record.consequent_name}", url: r.tag_implication_url(record), author: a(record.creator) }
    when Ticket
      { color: GREEN, title: "Ticket Created", url: r.ticket_url(record), author: a(record.creator) }
    when User
      { color: GREEN, title: "User Created", description: "Name: #{record.name}", url: r.user_url(record), author: a(record) }
    when UserTextVersion
      return if record.version == 1
      { color: YELLOW, title: "User Text Edited", url: r.user_text_versions_url(search: { user_id: record.user_id }), author: a(record.updater) }
    when WikiPage
      { color: GREEN, title: "Wiki Page Created", url: r.wiki_page_url(record), author: a(record.creator) }
    when WikiPageVersion
      return if record.version == 1
      { color: YELLOW, title: "Wiki Page Edited", url: r.wiki_page_version_url(record), author: a(record.updater) }
    end
  rescue Exception => e
    ExceptionLog.add!(e, source: "DiscordNotification#embed", record_type: record.class.name, record_id: record.id)
  end

  def execute!
    return if webhook_url.blank? || Rails.env.test?

    embed = self.embed
    return if embed.blank?

    conn = Faraday.new(FemboyFans.config.faraday_options)
    conn.post(webhook_url, {
      embeds: [embed],
    }.to_json, { content_type: "application/json" })
  rescue Exception => e
    ExceptionLog.add!(e, source: "DiscordNotification#execute!", record_type: record.class.name, record_id: record.id)
  end

  private

  def r
    Rails.application.routes.url_helpers
  end

  def u(user)
    "[#{user.name}](#{r.user_url(user)})"
  end

  def a(user)
    a = { url: r.user_url(user), name: user.name }
    a[:icon_url] = user.avatar.large_file_url if user.avatar.present?
    a
  end
end
