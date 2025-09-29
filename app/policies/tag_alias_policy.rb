# frozen_string_literal: true

class TagAliasPolicy < TagRelationshipPolicy
  def model
    TagAlias
  end
end
