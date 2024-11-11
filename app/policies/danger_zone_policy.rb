# frozen_string_literal: true

class DangerZonePolicy < ApplicationPolicy
  def index?
    user.is_admin?
  end

  def uploading_limits?
    user.is_admin?
  end

  def hide_pending_posts?
    user.is_admin?
  end
end
