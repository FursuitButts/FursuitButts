# frozen_string_literal: true

class AvoidPostingVersion < ApplicationRecord
  belongs_to_user(:updater, ip: true)
  belongs_to(:avoid_posting)
  has_one(:artist, through: :avoid_posting)
  delegate(:artist_id, :artist_name, to: :avoid_posting)

  def status
    if is_active?
      "Active"
    else
      "Deleted"
    end
  end

  def previous
    AvoidPostingVersion.where(avoid_posting_id: avoid_posting_id).where(AvoidPostingVersion.arel(:updated_at).lt(updated_at)).order(updated_at: :desc).first
  end

  module SearchMethods
    def apply_order(params)
      order_with({
        avoid_posting_id: { avoid_posting_id: :desc },
        artist_id:        -> { joins(:avoid_posting).order("avoid_postings.artist_id": :desc) },
        artist_id_asc:    -> { joins(:avoid_posting).order("avoid_postings.artist_id": :asc) },
        artist_id_desc:   -> { joins(:avoid_posting).order("avoid_postings.artist_id": :desc) },
        artist_name:      -> { joins(:artist).order("artists.name": :asc) },
        artist_name_asc:  -> { joins(:artist).order("artists.name": :asc) },
        artist_name_desc: -> { joins(:artist).order("artists.name": :desc) },
      }, params[:order])
    end

    def query_dsl
      super
        .field(:is_active)
        .field(:avoid_posting_id)
        .field(:artist_id, "avoid_postings.artist_id") { |q| q.joins(:avoid_posting) }
        .field(:artist_name, "artists.name") { |q| q.joins(avoid_posting: :artist) }
        .association(:updater)
        .association(:avoid_posting)
        .association(avoid_posting: :artist)
    end
  end

  extend(SearchMethods)

  def self.available_includes
    %i[artist updater avoid_posting]
  end
end
