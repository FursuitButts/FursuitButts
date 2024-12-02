# frozen_string_literal: true

class BulkRelatedTagQueryPolicy < ApplicationPolicy
  def bulk?
    member?
  end
end
