# frozen_string_literal: true

class ArtistVersion < ApplicationRecord
  array_attribute(:urls)
  array_attribute(:other_names)

  belongs_to_user(:updater, ip: true, counter_cache: "artist_update_count")
  belongs_to(:artist)
  belongs_to_user(:linked_user, optional: true)

  module SearchMethods
    def apply_order(params)
      order_with(%i[artist_id name], params[:order])
    end

    def query_dsl
      super
        .field(:artist_name, :name)
        .field(:artist_id)
        .field(:ip_addr, :updater_ip_addr)
        .association(:updater)
    end
  end

  extend(SearchMethods)

  def previous
    ArtistVersion.where(artist_id: artist_id).where.lt(created_at: created_at).order(created_at: :desc).first
  end

  def self.available_includes
    %i[artist updater]
  end
end
