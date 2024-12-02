# frozen_string_literal: true

class PostReplacementPolicy < ApplicationPolicy
  def create?
    member? && user.can_replace?
  end

  def approve?
    approver?
  end

  def reject?
    approver?
  end

  def reject_with_reason?
    approver?
  end

  def promote?
    approver?
  end

  def toggle_penalize?
    approver?
  end

  def destroy?
    user.is_admin?
  end

  def permitted_attributes
    attr = %i[replacement_url replacement_file reason source]
    attr += %i[as_pending] if approver?
    attr
  end

  def permitted_search_params
    super + %i[file_ext md5 status creator_id creator_name approver_id approver_name rejector_id rejector_name uploader_name_on_approve uploader_id_on_approve]
  end

  def api_attributes
    super - %i[storage_id protected uploader_id_on_approve penalize_uploader_on_approve previous_details] + %i[file_url]
  end
end
