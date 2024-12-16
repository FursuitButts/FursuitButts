# frozen_string_literal: true

module Security
  class DashboardPolicy < ApplicationPolicy
    def index?
      user.is_admin?
    end
  end
end
