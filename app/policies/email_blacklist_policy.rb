# frozen_string_literal: true

class EmailBlacklistPolicy < ApplicationPolicy
  def index?
    user.is_admin?
  end

  def create?
    user.is_admin?
  end

  def destroy?
    user.is_admin?
  end

  def permitted_attributes
    %i[domain reason]
  end

  def permitted_search_params
    super + %i[domain reason] + nested_search_params(creator: User)
  end
end
