# frozen_string_literal: true

class ForumTopicPolicy < ApplicationPolicy
  def create?
    min_level? && (!record.is_a?(ForumTopic) || record.category.can_create_within?(user))
  end

  def show?
    min_level?
  end

  def update?
    min_level? && (!record.is_a?(ForumTopic) || record.editable_by?(user))
  end

  def destroy?
    min_level? && (!record.is_a?(ForumTopic) || record.can_delete?(user))
  end

  def hide?
    min_level? && (!record.is_a?(ForumTopic) || record.can_hide?(user))
  end

  def unhide?
    user.is_moderator? && min_level? && (!record.is_a?(ForumTopic) || record.can_hide?(user))
  end

  def lock?
    min_level? && user.is_moderator?
  end

  def unlock?
    min_level? && user.is_moderator?
  end

  def sticky?
    min_level? && user.is_moderator?
  end

  def unsticky?
    min_level? && user.is_moderator?
  end

  def subscribe?
    min_level?
  end

  def unsubscribe?
    min_level?
  end

  def mute?
    min_level?
  end

  def unmute?
    min_level?
  end

  def move?
    min_level? && user.is_moderator?
  end

  def mark_as_read?
    min_level? && unbanned?
  end

  def merge?
    min_level? && user.is_moderator?
  end

  def unmerge?
    min_level? && user.is_moderator?
  end

  def min_level?
    !record.is_a?(ForumTopic) || record.visible?(user)
  end

  def permitted_attributes
    opattr = %i[id body]
    opattr += %i[allow_voting] if !record.try(:original_post).is_a?(ForumPost) || (!record.original_post.is_aibur? && (user.is_admin? || !record.original_post.allow_voting?)) # Disallow users disabling voting
    attr = [:title, :category_id, { original_post_attributes: opattr }]
    attr += %i[is_sticky is_locked] if user.is_moderator?
    attr
  end

  def permitted_attributes_for_merge
    %i[target_topic_id]
  end

  def permitted_attributes_for_move
    %i[category_id]
  end

  def permitted_search_params
    super + %i[title title_matches category_id is_sticky is_locked is_hidden creator_id creator_name order]
  end

  def api_attributes
    super + %i[creator_name updater_name]
  end

  def html_data_attributes
    super + [:is_read?, { category: %i[id name] }]
  end

  def visible_for_search(relation)
    q = super
    q = q.joins(:category).merge(ForumCategory.viewable(user))
    q = q.where("forum_topics.is_hidden": false).or(q.where("forum_topics.creator_id": user.id)) unless user.is_moderator?
    q
  end
end
