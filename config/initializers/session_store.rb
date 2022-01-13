# Be sure to restart your server when you modify this file.

# TODO: rename session
Rails.application.config.session_store :cookie_store, key: '_danbooru_session', same_site: :lax, secure: true, domain: ".#{Danbooru.config.hostname}"
Rails.application.config.action_dispatch.cookies_same_site_protection = :lax
