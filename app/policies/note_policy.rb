# frozen_string_literal: true

class NotePolicy < ApplicationPolicy
  def create?
    member? && min_level?
  end

  def update?
    create? && min_level?
  end

  def revert?
    update? && min_level?
  end

  def destroy?
    update? && min_level?
  end

  def min_level?
    return true if record == Post || (record.is_a?(Post) && record.can_edit?(user))
    return true if record == Note || (record.is_a?(Note) && (!record.post.is_a?(Post) || record.post.can_edit?(user)))
    false
  end

  def permitted_attributes
    %i[x y width height body]
  end

  def permitted_attributes_for_create
    super + %i[post_id html_id]
  end

  def permitted_search_params
    super + %i[body_matches is_active post_id post_tags_match post_note_updater_id post_note_updater_name creator_id creator_name] + nested_search_params(creator: User, post: Post)
  end

  def api_attributes
    super + %i[creator_name]
  end
end
