# frozen_string_literal: true

class PostVersionPolicy < ApplicationPolicy
  def undo?
    member?
  end

  def api_attributes
    super + %i[updater_name]
  end
end
