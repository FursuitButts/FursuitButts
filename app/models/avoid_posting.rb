# frozen_string_literal: true

class AvoidPosting < ApplicationRecord
  belongs_to_user(:creator, ip: true, clones: :updater)
  belongs_to_user(:updater, ip: true)
  soft_deletable(:is_active)
  resolvable(:destroyer)
  belongs_to(:artist)
  has_many(:versions, -> { order("avoid_posting_versions.id": :asc) }, class_name: "AvoidPostingVersion", dependent: :destroy)
  validates(:artist_id, uniqueness: { message: "already has an avoid posting entry" })
  validates(:details, length: { maximum: 1024 })
  validates(:staff_notes, length: { maximum: 4096 })
  before_validation(:initialize_artist_creator, on: :create)
  after_create(:log_create)
  after_create(:create_version)
  after_update(:log_update, if: :saved_change_to_watched_attributes?)
  after_update(:create_version, if: :saved_change_to_watched_attributes?)
  after_destroy(:log_destroy)
  validates_associated(:artist)
  accepts_nested_attributes_for(:artist)
  after_commit(:invalidate_cache)

  def initialize_artist_creator
    return if artist.blank?
    artist.creator ||= creator
  end

  module LogMethods
    def log_create
      ModAction.log!(creator, :avoid_posting_create, self, artist_name: artist_name)
    end

    def saved_change_to_watched_attributes?
      saved_change_to_is_active? || saved_change_to_details? || saved_change_to_staff_notes?
    end

    def log_update
      entry = { artist_name: artist_name }
      if saved_change_to_is_active?
        action = is_active? ? :avoid_posting_undelete : :avoid_posting_delete
        ModAction.log!(updater, action, self, **entry)
        # only log delete/undelete if only is_active is changed
        return if previous_changes.keys.all? { |key| %w[updater_id updated_at is_active].include?(key) }
      end
      entry = entry.merge({ details: details, old_details: details_before_last_save }) if saved_change_to_details?
      entry = entry.merge({ staff_notes: staff_notes, old_staff_notes: staff_notes_before_last_save }) if saved_change_to_staff_notes?

      ModAction.log!(updater, :avoid_posting_update, self, **entry)
    end

    def log_destroy
      ModAction.log!(destroyer, :avoid_posting_destroy, self, artist_name: artist_name)
    end
  end

  def create_version
    AvoidPostingVersion.create({
      avoid_posting: self,
      updater:       updater,
      details:       details,
      staff_notes:   staff_notes,
      is_active:     is_active,
    })
  end

  def status
    if is_active?
      "Active"
    else
      "Deleted"
    end
  end

  module ArtistMethods
    delegate(:other_names, :other_names_string, :linked_user_id, :linked_user, :any_name_matches, to: :artist, allow_nil: true)
    delegate(:name, to: :artist, prefix: true, allow_nil: true)
  end

  module SearchMethods
    def search(params, user, visible: true)
      super.if(params[:is_active].nil?, -> { active })
    end

    def query_dsl
      super
        .field(:is_active)
        .field(:artist_id)
        .field(:artist_name, "artists.name") { |q| q.joins(:artist) }
        .field(:details)
        .field(:staff_notes)
        .field(:ip_addr, :creator_ip_addr)
        .field(:updater_ip_addr)
        .association(:creator)
        .association(:updater)
        .association(:artist)
    end

    def apply_order(params)
      order_with({
        artist_id:        { artist_id: :desc },
        artist_name:      -> { joins(:artist).order("artists.name": :asc) },
        artist_name_asc:  -> { joins(:artist).order("artists.name": :asc) },
        artist_name_desc: -> { joins(:artist).order("artists.name": :desc) },
      }, params[:order])
    end
  end

  def header
    first = artist_name[0]
    if first =~ /\d/
      "#"
    elsif first =~ /[a-z]/
      first.upcase
    else
      "?"
    end
  end

  def all_names
    return artist_name.tr("_", " ") if other_names.blank?
    "#{artist_name} / #{other_names.join(' / ')}".tr("_", " ")
  end

  def pretty_details
    return details if details.present?
    return "Only the artist is allowed to post." if linked_user_id.present?
    ""
  end

  def invalidate_cache
    Cache.delete("avoid_posting_list")
  end

  include(LogMethods)
  include(ArtistMethods)
  extend(SearchMethods)

  def self.available_includes
    %i[artist creator updater]
  end
end
