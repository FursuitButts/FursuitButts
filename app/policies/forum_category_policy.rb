# frozen_string_literal: true

class ForumCategoryPolicy < ApplicationPolicy
  def show?
    !record.is_a?(ForumCategory) || user.level >= record.can_view
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

  def permitted_attributes
    %i[name can_create can_view description order]
  end

  def permitted_attributes_for_move_all_topics
    %i[new_category_id]
  end
end
