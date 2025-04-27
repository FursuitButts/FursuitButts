# frozen_string_literal: true

class MascotPolicy < ApplicationPolicy
  def create?
    user.is_admin?
  end

  def update?
    user.is_admin?
  end

  def destroy?
    user.is_admin?
  end

  def permitted_attributes
    %i[file display_name background_color artist_url artist_name available_on_string active hide_anonymous]
  end

  def api_attributes
    super + %i[file_url md5 file_ext file_size image_width image_height] - %i[mascot_media_asset_id]
  end
end
