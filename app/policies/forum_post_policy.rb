# frozen_string_literal: true

class ForumPostPolicy < ApplicationPolicy
  def show?
    min_level?
  end

  def new?
    min_level? && (!record.is_a?(ForumPost) || record.topic.blank? || record.topic.can_reply?(user))
  end

  def create?
    min_level? && (!record.is_a?(ForumPost) || (record.topic.present? && record.topic.can_reply?(user)))
  end

  def update?
    min_level? && (!record.is_a?(ForumPost) || record.editable_by?(user))
  end

  def destroy?
    min_level? && (!record.is_a?(ForumPost) || record.can_delete?(user))
  end

  def hide?
    min_level? && (!record.is_a?(ForumPost) || record.can_hide?(user))
  end

  def unhide?
    user.is_moderator? && min_level? && (!record.is_a?(ForumPost) || record.can_hide?(user))
  end

  def warning?
    min_level? && user.is_moderator?
  end

  def mark_spam?
    user.is_moderator?
  end

  def mark_not_spam?
    user.is_moderator?
  end

  def min_level?
    return true unless record.is_a?(ForumPost) && record.topic.present?
    return false unless record.topic.visible?(user)
    return false if record.topic.is_hidden? && !record.topic.can_hide?(user)
    return false if record.is_hidden? && !record.can_hide?(user)
    record.visible?(user)
  end

  def permitted_attributes
    %i[body]
  end

  def permitted_attributes_for_create
    super + %i[topic_id allow_voting]
  end

  def permitted_attributes_for_update
    attr = super
    attr += %i[allow_voting] if !record.is_a?(ForumPost) || (!record.is_aibur? && (user.is_admin? || !record.allow_voting?)) # Disallow users disabling voting
    attr
  end

  def permitted_search_params
    super + %i[creator_id creator_name topic_id topic_title_matches body_matches topic_category_id is_hidden linked_to not_linked_to]
  end

  def api_attributes
    super - %i[notified_mentions] + %i[mentions creator_name updater_name]
  end

  def html_data_attributes
    super + %i[topic]
  end
end
