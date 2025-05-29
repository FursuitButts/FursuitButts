# frozen_string_literal: true

class ArtistVersion < ApplicationRecord
  array_attribute(:urls)
  array_attribute(:other_names)

  belongs_to_updater(counter_cache: "artist_update_count")
  belongs_to(:artist)
  belongs_to(:linked_user, class_name: "User", optional: true)

  module SearchMethods
    def for_user(user_id)
      where("updater_id = ?", user_id)
    end

    def search(params)
      q = super

      if params[:artist_name].present?
        q = q.where("name like ? escape E'\\\\'", params[:artist_name].to_escaped_for_sql_like)
      end

      q = q.where_user(:updater_id, :updater, params)

      if params[:artist_id].present?
        q = q.where(artist_id: params[:artist_id].split(",").map(&:to_i))
      end

      if params[:ip_addr].present?
        q = q.where("updater_ip_addr <<= ?", params[:ip_addr])
      end

      if params[:order] == "name"
        q = q.order("artist_versions.name").default_order
      else
        q = q.apply_basic_order(params)
      end

      q
    end
  end

  extend(SearchMethods)

  def previous
    ArtistVersion.where("artist_id = ? and created_at < ?", artist_id, created_at).order("created_at desc").first
  end

  def self.available_includes
    %i[artist updater]
  end
end
