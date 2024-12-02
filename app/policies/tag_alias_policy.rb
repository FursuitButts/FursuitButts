# frozen_string_literal: true

class TagAliasPolicy < ApplicationPolicy
  def create?
    # record: TagAliasRequest
    member?
  end

  def destroy?
    return member? unless record.is_a?(TagAlias)
    member? && record.rejectable_by?(user)
  end

  def update?
    return member? unless record.is_a?(TagAlias)
    member? && record.editable_by?(user)
  end

  def approve?
    return member? && user.can_manage_aibur? unless record.is_a?(TagAlias)
    member? && record.approvable_by?(user)
  end

  def permitted_attributes
    %i[antecedent_name consequent_name]
  end

  def permitted_attributes_for_create
    params = super + %i[reason forum_topic_id]
    params += %i[skip_forum] if user.is_admin?
    params
  end

  def permitted_search_params
    super + %i[name_matches antecedent_name consequent_name status antecedent_tag_category consequent_tag_category creator_id creator_name approver_id approver_name]
  end
end
