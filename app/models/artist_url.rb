# frozen_string_literal: true

class ArtistUrl < ApplicationRecord
  before_validation(:initialize_normalized_url, on: :create)
  before_validation(:normalize)
  validates(:url, presence: true, uniqueness: { scope: :artist_id })
  validates(:url, length: { in: 1..4096 })
  validate(:validate_url_format)
  belongs_to(:artist, touch: true)

  def self.parse_prefix(url)
    prefix, url = url.match(/\A(-)?(.*)/)[1, 2]
    is_active = prefix.nil?

    [is_active, url]
  end

  def self.normalize(url)
    if url.nil?
      nil
    else
      url = url.sub(%r{^https://}, "http://")
      url = url.sub(%r{^http://([^/]+)}i, &:downcase)

      url = url.gsub(%r{/+\Z}, "")
      url = url.gsub(%r{^https://}, "http://")
      "#{url}/"
    end
  end

  module SearchMethods
    def apply_order(params)
      order_with(%i[artist_id url normalized_url], params[:order])
    end

    def query_dsl
      super
        .field(:artist_id)
        .field(:is_active)
        .field(:url)
        .field(:normalized_url)
        .field(:artist_name, "artists.name") { |q| q.joins(:artist) }
        .field(:url_matches, :url, wildcard: true)
        .field(:normalized_url_matches, :normalized_url, wildcard: true)
        .association(:artist)
    end
  end

  extend(SearchMethods)

  # sites apearing at the start have higher priority than those below
  SITES_PRIORITY_ORDER = [
    "furaffinity.net",
    "deviantart.com",
    "twitter.com",
    "pixiv.net",
    "pixiv.me",
    "inkbunny.net",
    "sofurry.com",
    "weasyl.com",
    "furrynetwork.com",
    "itaku.ee",
    "tumblr.com",
    "newgrounds.com",
    "derpibooru.org",
    "cohost.org",
    "hentai-foundry.com",
    "artstation.com",
    "baraag.net",
    "pawoo.net",
    "skeb.jp",
    "pillowfort.social",
    "reddit.com",
    "bsky.app",
    "youtube.com",
    "t.me",
    "instagram.com",
    "vk.com",
    "facebook.com",
    "tiktok.com",
    # livestreams
    "picarto.tv",
    "piczel.tv",
    "twitch.tv",
    # support the artist
    "patreon.com",
    "subscribestar.adult",
    "ko-fi.com",
    "commishes.com",
    "boosty.to",
    "fanbox.cc",
    "itch.io",
    "gumroad.com",
    "redbubble.com",
    "etsy.com",
    # misc
    "discord.gg",
    "discord.com",
    "trello.com",
    "curiouscat.me",
    "toyhou.se",
    "linktr.ee",
    "carrd.co",
  ].reverse!

  # higher priority will apear higher in the artist url list
  # inactive urls will be pushed to the bottom
  def priority
    prio = 0
    prio -= 1000 unless is_active
    host = Addressable::URI.parse(url).domain
    prio += SITES_PRIORITY_ORDER.index(host).to_i
    prio
  end

  def normalize
    self.normalized_url = self.class.normalize(url)
  end

  def initialize_normalized_url
    self.normalized_url = url
  end

  def to_s
    if is_active?
      url
    else
      "-#{url}"
    end
  end

  def validate_url_format
    uri = Addressable::URI.parse(url)
    errors.add(:url, "'#{uri}' must begin with http:// or https:// ") unless uri.scheme.in?(%w[http https])
  rescue Addressable::URI::InvalidURIError => e
    errors.add(:url, "'#{uri}' is malformed: #{e}")
  end

  def self.available_includes
    %i[artist]
  end
end
