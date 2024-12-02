# frozen_string_literal: true

class PostSetMaintainerPolicy < ApplicationPolicy
  def index?
    member?
  end

  def approve?
    record.user_id == user.id && %w[blocked approved].exclude?(record.status)
  end

  def block?
    record.user_id == user.id && record.status != "blocked"
  end

  def cancel?
    !(record.status == "blocked" || (record.status == "cooldown" && record.created_at > 24.hours.ago))
  end

  def deny?
    record.user_id == user.id
  end
end
