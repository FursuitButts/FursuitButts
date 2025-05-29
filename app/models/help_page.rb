# frozen_string_literal: true

class HelpPage < ApplicationRecord
  normalizes(:name, with: ->(name) { name.downcase.strip.tr(" ", "_") })
  after_create(:log_create)
  after_update(:log_update)
  after_destroy(:invalidate_cache)
  after_destroy(:log_delete)
  after_save(:invalidate_cache)
  belongs_to(:wiki_page)
  delegate(:title, to: :wiki_page, prefix: true, allow_nil: true)

  def wiki_page_title=(name)
    self.wiki_page = WikiPage.titled(name)
  end

  def invalidate_cache
    Cache.delete("help_index")
    true
  end

  def pretty_title
    title.presence || name.titleize
  end

  def related_array
    related.split(",").map(&:strip)
  end

  def self.pretty_related_title(related, help_pages)
    related_help_page = help_pages.find { |help_page| help_page.name == related }

    return related_help_page.pretty_title if related_help_page

    related.titleize
  end

  def self.help_index
    Cache.fetch("help_index", expires_in: 12.hours) { HelpPage.all.sort_by(&:pretty_title) }
  end

  module LogMethods
    def log_create
      ModAction.log!(:help_create, self, name: name, wiki_page_title: wiki_page_title, wiki_page_id: wiki_page_id)
    end

    def log_update
      ModAction.log!(:help_update, self, name: name, wiki_page_title: wiki_page_title, wiki_page_id: wiki_page_id)
    end

    def log_delete
      ModAction.log!(:help_delete, self, name: name, wiki_page_title: wiki_page_title, wiki_page_id: wiki_page_id)
    end
  end

  include(LogMethods)

  def self.available_includes
    %i[wiki_page]
  end
end
