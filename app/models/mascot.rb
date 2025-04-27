# frozen_string_literal: true

class Mascot < ApplicationRecord
  has_media_asset(:mascot_media_asset)
  belongs_to_creator

  array_attribute :available_on, parse: /[^,]+/, join_character: ","
  attr_reader :direct_url # required for the media asset shared code

  validates :display_name, uniqueness: { case_sensitive: false }
  validates :display_name, :background_color, :artist_url, :artist_name, presence: true
  validates :artist_url, format: { with: %r{\Ahttps?://}, message: "must start with http:// or https://" }, length: { maximum: 1_000 }
  validates :display_name, :artist_name, length: { maximum: 100 }
  validates :file, presence: true, on: :create

  after_create :log_create
  after_update :log_update
  after_destroy :log_delete
  after_destroy { mascot_media_asset.destroy }

  def self.active_for_browser
    mascots = Cache.fetch("active_mascots", expires_in: 1.day) do
      query = Mascot.where(active: true).where("? = ANY(available_on)", FemboyFans.config.app_name).with_assets
      mascots = query.map do |mascot|
        mascot.slice(:id, :background_color, :artist_url, :artist_name, :hide_anonymous).merge(background_url: mascot.file_url)
      end
      mascots.index_by { |mascot| mascot["id"] }
    end
    if CurrentUser.user.nil? || CurrentUser.user.is_anonymous?
      mascots.each_pair do |id, mascot|
        mascots.delete(id) if mascot[:hide_anonymous]
      end
    end
    mascots
  end

  def invalidate_cache
    Cache.delete("active_mascots")
  end

  def self.search(params)
    q = super
    q.order("lower(artist_name)")
  end

  module LogMethods
    def log_create
      ModAction.log!(:mascot_create, self)
    end

    def log_update
      return if saved_changes.empty?
      ModAction.log!(:mascot_update, self)
    end

    def log_delete
      ModAction.log!(:mascot_delete, self)
    end
  end

  include FileMethods
  include LogMethods

  def self.available_includes
    %i[creator]
  end
end
