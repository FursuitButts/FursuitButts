# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def for_post?
    index?
  end

  def show?
    !record.is_a?(Comment) || record.visible_to?(user)
  end

  def update?
    member? && (!record.is_a?(Comment) || record.editable_by?(user))
  end

  def hide?
    member? && (!record.is_a?(Comment) || record.can_hide?(user))
  end

  def unhide?
    user.is_moderator?
  end

  def warning?
    user.is_moderator?
  end

  def mark_spam?
    user.is_moderator?
  end

  def mark_not_spam?
    user.is_moderator?
  end

  def destroy?
    user.is_admin?
  end

  def permitted_attributes
    attr = %i[body]
    attr += %i[is_sticky is_hidden] if user.is_moderator?
    attr
  end

  def permitted_attributes_for_create
    super + %i[post_id]
  end

  def permitted_search_params
    params = super + %i[body_matches post_id post_tags_match creator_name creator_id updater_name updater_id post_note_updater_name post_note_updater_id poster_id poster_name is_sticky order] + nested_search_params(creator: User, poster: User)
    params += %i[is_hidden is_spam] if user.is_moderator?
    params += %i[ip_addr updater_ip_addr] if can_search_ip_addr?
    params
  end

  def api_attributes
    super - %i[notified_mentions] + %i[mentions creator_name updater_name]
  end

  def visible_for_search(relation)
    q = super
    q = q.where("comments.score": user.comment_threshold..).or(q.where("comments.is_sticky": true))
    return q if user.is_moderator?
    q = q.joins(:post).where("comments.is_sticky": true).or(q.where("posts.is_comment_disabled": false)).or(q.where("comments.creator_id": user.id))
    qq = q.where("comments.is_hidden": false).or(q.where("comments.creator_id": user.id))
    qq = qq.or(q.where("comments.is_sticky": true)) if user.is_janitor?
    qq
  end
end
