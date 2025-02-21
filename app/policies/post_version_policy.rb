# frozen_string_literal: true

class PostVersionPolicy < ApplicationPolicy
  def undo?
    member? && min_level?
  end

  def min_level?
    return true if record == Post || (record.is_a?(Post) && record.can_edit?(user))
    return true if record == PostVersion || (record.is_a?(PostVersion) && (!record.post.is_a?(Post) || record.post.can_edit?(user)))
    false
  end

  def api_attributes
    super + %i[updater_name]
  end
end
