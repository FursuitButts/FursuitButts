# Be sure to restart your server when you modify this file.

# TODO: rename session
Rails.application.config.session_store :cookie_store, key: 'yiff', same_site: :lax, secure: true, httponly: true
Rails.application.config.action_dispatch.cookies_same_site_protection = :lax
