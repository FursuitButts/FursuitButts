# frozen_string_literal: true

class DtextLink < ApplicationRecord
  belongs_to(:model, polymorphic: true)
  belongs_to(:linked_wiki, primary_key: :title, foreign_key: :link_target, class_name: "WikiPage", optional: true)
  belongs_to(:linked_tag, primary_key: :name, foreign_key: :link_target, class_name: "Tag", optional: true)
  enum(:link_type, { wiki_link: 0, external_link: 1 })
  MODEL_TYPES = %w[WikiPage ForumPost Pool].freeze

  before_validation(:normalize_link_target)
  validates(:link_target, uniqueness: { scope: %i[model_type model_id] })

  scope(:wiki_page, -> { where(model_type: "WikiPage") })
  scope(:forum_post, -> { where(model_type: "ForumPost") })
  scope(:pool, -> { where(model_type: "Pool") })

  def self.new_from_dtext(dtext)
    links = []

    links += DTextHelper.parse_wiki_titles(dtext).map do |link|
      DtextLink.new(link_type: :wiki_link, link_target: link)
    end

    links += DTextHelper.parse_external_links(dtext).map do |link|
      DtextLink.new(link_type: :external_link, link_target: link)
    end

    links
  end

  def normalize_link_target
    if wiki_link?
      self.link_target = WikiPage.normalize_title(link_target)
    end

    # postgres will raise an error if the link is more than 2712 bytes long
    # because it can't index values that take up more than 1/3 of an 8kb page.
    self.link_target = link_target.truncate(2048, omission: "")
  end

  module SearchMethods
    def query_dsl
      super
        .field(:link_type)
        .field(:link_target)
        .field(:model_type)
        .field(:model_id)
        .field(:wiki_page_title, "wiki_pages.title") { |q| q.joins(:linked_wiki) }
        .field(:tag_name, "tags.name") { |q| q.joins(:linked_tag) }
        .present(:has_linked_wiki, "wiki_pages.id") { |q| q.left_joins(:linked_wiki) }
        .present(:has_linked_tag, "tags.id") { |q| q.left_joins(:linked_tag) }
    end
  end

  extend(SearchMethods)

  def self.available_includes
    %i[model linked_wiki linked_tag]
  end

  delegate(:visible?, to: :model)
end
