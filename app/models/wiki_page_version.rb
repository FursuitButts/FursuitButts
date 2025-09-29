# frozen_string_literal: true

class WikiPageVersion < ApplicationRecord
  belongs_to(:wiki_page)
  belongs_to_user(:updater, ip: true, counter_cache: "wiki_update_count")
  delegate(:visible?, to: :wiki_page)

  module SearchMethods
    def query_dsl
      super
        .field(:wiki_page_id)
        .field(:title)
        .field(:body)
        .field(:protection_level)
        .field(:ip_addr, :updater_ip_addr)
        .association(:updater)
        .association(:wiki_page)
    end
  end

  extend(SearchMethods)

  def pretty_title
    title.tr("_", " ")
  end

  def previous
    return @previous if defined?(@previous)

    @previous = WikiPageVersion.where(wiki_page_id: wiki_page_id).where.lt(id: id).order(id: :desc).first
  end

  def category_id
    Tag.category_for(title)
  end

  def self.available_includes
    %i[updater wiki_page]
  end
end
