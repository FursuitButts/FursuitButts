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
    attr = %i[direct_url file reason source checksum]
    attr += %i[as_pending] if approver?
    attr
  end

  def permitted_search_params
    super + %i[file_ext md5 status creator_id creator_name approver_id approver_name rejector_id rejector_name uploader_name_on_approve uploader_id_on_approve post_id] + nested_search_params(creator: User, approver: User, rejector: User, uploader_on_approve: User)
  end

  def api_attributes
    super + %i[file_url md5 file_ext file_size image_width image_height creator_name media_asset_id] - %i[storage_id protected uploader_id_on_approve penalize_uploader_on_approve previous_details post_replacement_media_asset_id]
  end

  def visible_for_search(relation)
    q = super
    return q.not_rejected if user.is_anonymous?
    return q if user.is_staff?
    q.for_creator(user).or(q.not_rejected)
  end
end
