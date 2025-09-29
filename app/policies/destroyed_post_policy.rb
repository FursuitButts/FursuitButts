# frozen_string_literal: true

class DestroyedPostPolicy < ApplicationPolicy
  def index?
    user.is_admin?
  end

  def create?
    user.is_admin?
  end

  def update?
    user.is_owner?
  end

  def permitted_attributes_for_update
    %i[notify]
  end

  def permitted_search_params
    super + %i[destroyer_id destroyer_name destroyer_ip_addr uploader_id uploader_name uploader_ip_addr post_id md5 reason_matches] + nested_search_params(destroyer: User, uploader: User)
  end
end
