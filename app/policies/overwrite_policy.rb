# frozen_string_literal: true

# not a real policy, used as a replacement policy for inputs to return a specific value for the search/attribute check
class OverwritePolicy < ApplicationPolicy
  attr_reader(:value)

  def initialize(value)
    super(nil, nil)
    @value = value
  end

  def can_search_attribute?(_attr)
    value
  end

  def can_use_attribute?(_attr, _action = nil)
    value
  end
end
