# frozen_string_literal: true

class BulkUpdateRequestImportPolicy < ApplicationPolicy
  def create?
    user.is_owner?
  end
end
