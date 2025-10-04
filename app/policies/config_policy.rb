# frozen_string_literal: true

class ConfigPolicy < ApplicationPolicy
  def show?
    user.is_moderator?
  end

  def update?
    user.is_owner?
  end
end
