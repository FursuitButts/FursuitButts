# frozen_string_literal: true

class FavoritePolicy < ApplicationPolicy
  def index?
    unbanned? || user.is_pending?
  end

  def clear?
    unbanned? || user.is_pending?
  end

  def create?
    unbanned? || user.is_pending?
  end

  def destroy?
    unbanned? || user.is_pending?
  end

  def api_attributes
    super + %i[post]
  end
end
