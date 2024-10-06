# frozen_string_literal: true

# rdoc
#   A tag set represents a set of tags that are displayed together.
#   This class makes it easy to fetch the categories for all the
#   tags in one call instead of fetching them sequentially.

class TagSetPresenter < Presenter
  include Rails.application.routes.url_helpers

  attr_reader :tag_names

  # @param [Array<String>] tag_names a list of tags to present. Tags will be presented in
  # the order given. The list should not contain duplicates. The list may
  # contain tags that do not exist in the tags table, such as metatags.
  def initialize(tag_names)
    @tag_names = tag_names
  end

  def post_index_sidebar_tag_list_html(followed_tags:, current_query: "")
    html = +""
    if ordered_tags.present?
      html += "<ul>"
      ordered_tags.each do |tag|
        html << build_list_item(tag, current_query: current_query, followed: followed_tags.include?(tag.name))
      end
      html += "</ul>"
    end

    html.html_safe
  end

  def post_show_sidebar_tag_list_html(highlighted_tags:, followed_tags:, current_query: "")
    html = +""

    TagCategory::SPLIT_HEADER_LIST.each do |category|
      typetags = tags_for_category(category)

      next unless typetags.any?
      html += %(<h2 class="#{category}-tag-list-header tag-list-header" data-category="#{category}">#{TagCategory.get(category).header}</h2>)
      html += %(<ul class="#{category}-tag-list">)
      typetags.each do |tag|
        html += build_list_item(tag, current_query: current_query, highlight: highlighted_tags.include?(tag.name), followed: followed_tags.include?(tag.name))
      end
      html << "</ul>"
    end

    html.html_safe
  end

  # compact (horizontal) list, as seen in the /comments index.
  def inline_tag_list_html(link_type = :tag)
    html = TagCategory::CATEGORIZED_LIST.map do |category|
      tags_for_category(category).map do |tag|
        %(<li class="category-#{tag.category}">#{tag_link(tag, tag.name, link_type)}</li>)
      end.join
    end.join
    %(<ul class="inline-tag-list">#{html}</ul>).html_safe
  end

  # the list of tags inside the tag box in the post edit form.
  def split_tag_list_text
    TagCategory::CATEGORIZED_LIST.map do |category|
      tags_for_category(category).map(&:name).join(" ")
    end.compact_blank.join(" \n")
  end

  def humanized_essential_tag_string(category_list: TagCategory::HUMANIZED_LIST, default: "")
    @humanized_essential_tag_string ||= begin
      strings = category_list.map do |category|
        mapping = TagCategory.get(category)
        max_tags = mapping.limit || 0
        regexmap = mapping.regex || //
        formatstr = mapping.formatstr || "%s"
        excluded_tags = mapping.exclusion || []

        type_tags = tags_for_category(category).map(&:name) - excluded_tags
        next if type_tags.empty?

        if max_tags > 0 && type_tags.length > max_tags
          type_tags = type_tags.sort_by { |x| -x.size }.take(max_tags) + ["etc"]
        end

        if regexmap != //
          type_tags = type_tags.map { |tag| tag.match(regexmap)[1] }
        end

        if category == "copyright" && tags_for_category("character").blank?
          type_tags.to_sentence
        else
          formatstr % type_tags.to_sentence
        end
      end

      strings = strings.compact.join(" ").tr("_", " ")
      output = strings.presence || default
      output
    end
  end

  private

  def tags
    @tags ||= Tag.where(name: tag_names).select(:name, :post_count, :category)
  end

  def tags_by_category
    @tags_by_category ||= ordered_tags.group_by(&:category)
  end

  def tags_for_category(category_name)
    category = TagCategory.mapping[category_name.downcase]
    tags_by_category[category] || []
  end

  def ordered_tags
    @ordered_tags ||= begin
      names_to_tags = tags.index_by(&:name)

      ordered = tag_names.map do |name|
        names_to_tags[name] || Tag.new(name: name).freeze
      end
      ordered
    end
  end

  def build_list_item(tag, current_query: "", highlight: false, followed: false)
    name = tag.name
    count = tag.post_count
    category = tag.category

    html = %(<li class="category-#{tag.category}">)

    if category == TagCategory.artist
      html += %(<a class="wiki-link" rel="nofollow" href="/artists/show_or_new?name=#{u(name)}">?</a> )
    else
      html += %(<a class="wiki-link" rel="nofollow" href="/wiki_pages/show_or_new?title=#{u(name)}">?</a> )
    end

    html += %(<span class="tag-type">)

    if current_query.present?
      html += %(<a rel="nofollow" href="/posts?tags=#{u(current_query)}+#{u(name)}" class="search-inc-tag">+</a> )
      html += %(<a rel="nofollow" href="/posts?tags=#{u(current_query)}+-#{u(name)}" class="search-exl-tag">–</a> )
    end

    html += tag_link(tag, name.tr("_", " "))
    html += %(<i title="Uploaded by the artist" class="highlight fa-regular fa-circle-check"></i>) if highlight

    if count >= 10_000
      post_count = "#{count / 1_000}k"
    elsif count >= 1_000
      post_count = format("%.1fk", (count / 1_000.0))
    else
      post_count = count
    end

    is_underused_tag = count <= 1 && category == TagCategory.general
    klass = "color-muted post-count#{is_underused_tag ? ' low-post-count' : ''}"
    title = "New general tag detected. Check the spelling or populate it now."

    html += %(<span data-count='#{count}' class="#{klass}"#{is_underused_tag ? " title='#{title}'" : ''}>#{post_count}</span>)
    html += %(</span>)

    html += %(<div class="tag-actions" data-tag="#{tag.name}">)
    if CurrentUser.user.is_member?
      html += %(<span class="tag-action-blacklist"><a href="#" class="blacklist-tag-toggle" title="Blacklist Tag"><i class='fas fa-times'></i></a></span>)
      html += %(<span class="tag-action-follow"><a href="#" class="follow-button-minor" title="Follow Tag" data-followed="#{followed}"></a></span>)
    end
    html += %(</div>)

    html += "</li>"
    html
  end

  def tag_link(tag, link_text = tag.name, link_type = :tag)
    link = link_type == :wiki_page ? show_or_new_wiki_pages_path(title: tag.name) : posts_path(tags: tag.name)
    itemprop = 'itemprop="author"' if tag.artist?
    %(<a rel="nofollow" class="search-tag" #{itemprop} href="#{link}">#{h(link_text)}</a> )
  end
end
