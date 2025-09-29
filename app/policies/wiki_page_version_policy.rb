# frozen_string_literal: true

class WikiPageVersionPolicy < ApplicationPolicy
  def diff?
    index?
  end

  def permitted_search_params
    params = super + %i[updater_id updater_name wiki_page_id title body is_locked] + nested_search_params(updater: User, wiki_page: WikiPage)
    params += %i[ip_addr] if can_search_ip_addr?
    params
  end
end
