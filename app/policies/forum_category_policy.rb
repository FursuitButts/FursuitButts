# frozen_string_literal: true

class ForumCategoryPolicy < ApplicationPolicy
  def show?
    min_level?
  end

  def create?
    user.is_admin?
  end

  def update?
    user.is_admin?
  end

  def destroy?
    user.is_admin?
  end

  def reorder?
    user.is_admin?
  end

  def move_all_topics?
    user.is_admin?
  end

  def mark_as_read?
    unbanned? && min_level?
  end

  def mark_all_as_read?
    unbanned?
  end

  def min_level?
    !record.is_a?(ForumCategory) || user.level >= record.can_view
  end

  def permitted_attributes
    %i[name can_create can_view description order]
  end

  def permitted_attributes_for_move_all_topics
    %i[new_category_id]
  end
end
