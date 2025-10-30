# frozen_string_literal: true

class WikiPagePolicy < ApplicationPolicy
  def show_or_new?
    index?
  end

  def update?
    member? && unrestricted?
  end

  def destroy?
    user.is_admin? && unrestricted?
  end

  def revert?
    update?
  end

  def merge?
    user.is_admin?
  end

  def permitted_attributes
    attr = %i[body edit_reason]
    attr += %i[parent] if user.is_trusted?
    attr += %i[protection_level] if user.is_janitor?
    attr
  end

  def permitted_attributes_for_create
    super + %i[title]
  end

  def permitted_attributes_for_update
    attr = super
    attr += %i[title] if user.is_janitor?
    attr
  end

  def permitted_attributes_for_merge
    %i[target_wiki_page_id target_wiki_page_title]
  end

  def permitted_search_params
    params = super + %i[title title_matches body_matches creator_id creator_name updater_id updater_name protection_level parent linked_to not_linked_to] + nested_search_params(creator: User, updater: User)
    params += %i[ip_addr updater_ip_addr] if can_search_ip_addr?
    params
  end

  def api_attributes
    super + %i[creator_name category_id]
  end

  private

  def unrestricted?
    !record.is_a?(WikiPage) || !record.is_restricted?(user)
  end
end
