# frozen_string_literal: true

class ArtistPolicy < ApplicationPolicy
  def show_or_new?
    show?
  end

  def update?
    member? && (!record.is_a?(Artist) || !record.is_locked? || user.is_janitor?)
  end

  def destroy?
    user.is_admin?
  end

  def revert?
    member? && (!record.is_a?(Artist) || !record.is_locked? || user.is_janitor?)
  end

  def permitted_attributes
    attr = %i[other_names other_names_string url_string notes]
    attr += %i[linked_user_id is_locked] if user.is_janitor?
    attr
  end

  def permitted_attributes_for_create
    super + %i[name]
  end

  def permitted_attributes_for_update
    attr = super
    attr += %i[name] if user.is_janitor?
    attr
  end

  def permitted_search_params
    super + %i[name any_other_name_like any_name_matches any_name_or_url_matches url_matches creator_id creator_name linked_user_id linked_user_name has_tag is_linked is_active order] + nested_search_params(creator: User, linked_user: User)
  end
end
