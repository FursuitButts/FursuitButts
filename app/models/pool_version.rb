# frozen_string_literal: true

class PoolVersion < ApplicationRecord
  belongs_to_user(:updater, ip: true, counter_cache: "pool_update_count")
  undoable
  belongs_to(:pool)
  before_validation(:fill_version, on: :create)
  before_validation(:fill_changes, on: :create)

  module SearchMethods
    def default_order
      order(id: :desc)
    end

    def query_dsl
      super
        .field(:pool_id)
        .field(:ip_addr, :updater_ip_addr)
        .association(:updater)
        .association(:pool)
    end
  end

  extend(SearchMethods)

  def self.queue(pool, updater)
    create({
      pool_id:         pool.id,
      post_ids:        pool.post_ids,
      updater_id:      updater.id,
      updater_ip_addr: updater.ip_addr,
      description:     pool.description,
      name:            pool.name,
      is_ongoing:      pool.is_ongoing?,
      category:        pool.category,
    })
  end

  def self.calculate_version(pool_id)
    1 + where(pool_id: pool_id).maximum(:version).to_i
  end

  def fill_version
    self.version = PoolVersion.calculate_version(pool_id)
  end

  def fill_changes
    if previous
      self.added_post_ids = post_ids - previous.post_ids
      self.removed_post_ids = previous.post_ids - post_ids
    else
      self.added_post_ids = post_ids
      self.removed_post_ids = []
    end

    self.description_changed = previous.nil? || description != previous.description
    self.name_changed = previous.nil? || name != previous.name
    self.is_ongoing_changed = previous.nil? || is_ongoing != previous.is_ongoing
    self.category_changed = previous.nil? || category != previous.category
  end

  def previous
    @previous ||= PoolVersion.where(pool_id: pool_id).where.lt(version: version).order(version: :desc).first
  end

  def pool
    Pool.find(pool_id)
  end

  def updater
    User.find(updater_id)
  end

  def updater_name
    User.id_to_name(updater_id)
  end

  def pretty_name
    name&.tr("_", " ") || "(Unknown Name)"
  end

  def changes_text
    return %w[created] if version == 1
    list = []
    if added_post_ids.any? || removed_post_ids.any?
      text = "posts ("
      text += "+#{added_post_ids.size}, " if added_post_ids.any?
      text += "-#{removed_post_ids.size}" if removed_post_ids.any?
      list << "#{text.delete_suffix(', ')})"
    end
    list << "description" if description_changed?
    list << "name" if name_changed?
    list << "ongoing" if is_ongoing_changed?
    list << "category" if category_changed?
    list
  end

  def self.available_includes
    %i[pool updater]
  end
end
