# frozen_string_literal: true

class TagPolicy < ApplicationPolicy
  def meta_search?
    index?
  end

  def preview?
    member?
  end

  def update?
    return false if record && !record.category_editable_by?(user)
    member?
  end

  def correct?
    user.is_janitor?
  end

  def followed?
    member?
  end

  def followers?
    member?
  end

  def follow?
    member?
  end

  def unfollow?
    member?
  end

  def permitted_attributes
    attr = %i[category reason]
    attr += %i[is_locked] if user.is_admin?
    attr
  end

  def permitted_search_params
    super + %i[fuzzy_name_matches name_matches name category hide_empty has_wiki has_artist is_locked creator_id creator_name] + nested_search_params(creator: User)
  end
end
