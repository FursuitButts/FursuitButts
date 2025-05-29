# frozen_string_literal: true

class TagVersion < ApplicationRecord
  belongs_to_updater
  belongs_to(:tag)

  module SearchMethods
    def search(params)
      q = super.includes(:updater, :tag)

      if params[:tag].present?
        tag = Tag.find_by_normalized_name(params[:tag])
        q = q.where(tag: tag)
      end

      q = q.where_user(:updater_id, :updater, params)

      q.apply_basic_order(params)
    end
  end

  extend(SearchMethods)

  def previous
    TagVersion.where(tag_id: tag_id, created_at: ...created_at).order("created_at desc").first
  end

  def category_changed?
    previous && previous.category != category
  end

  def is_locked_changed?
    previous && previous.is_locked? != is_locked?
  end

  def self.available_includes
    %i[tag updater]
  end
end
