# frozen_string_literal: true

# record: Post
class PostApprovalPolicy < ApplicationPolicy
  def create?
    approver?
  end

  def destroy?
    approver?
  end

  def permitted_search_params
    super + nested_search_params(user: User, post: Post)
  end
end
