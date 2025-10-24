# frozen_string_literal: true

if Rails.env.development?
  Rails.application.config.after_initialize do
    Bullet.enable = true
    Bullet.alert = false
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
    Bullet.always_append_html_body = true
    Bullet.stacktrace_excludes = %w[silence_healthcheck_logging]
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Post", association: :uploader)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "ForumPost", association: :topic)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "ForumPost", association: :spam_ticket)
    Bullet.add_safelist(type: :unused_eager_loading, class_name: "Comment", association: :spam_ticket)
  end
end
