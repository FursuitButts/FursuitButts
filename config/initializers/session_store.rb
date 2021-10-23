# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store, key: 'yiff', same_site: :lax, secure: Rails.env.production?, domain: Rails.env.production? ? ".#{Danbooru.config.hostname}" : "e621.local"
Rails.application.config.action_dispatch.cookies_same_site_protection = :lax
