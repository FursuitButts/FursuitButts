# frozen_string_literal: true

class DtextLinkPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[link_target link_type model_type model_id has_linked_wiki has_linked_tag wiki_page_title tag_name]
  end

  def visible_for_search(relation)
    q = super
    q.wiki_page.or(q.forum_post.where.not(model_id: ForumPost.not_visible(user))).or(q.pool)
  end
end
