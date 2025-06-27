# frozen_string_literal: true

class UserBlock < ApplicationRecord
  belongs_to_user(:user)
  belongs_to_user(:target)
  resolvable(:updater)
  resolvable(:destroyer)
  validates(:target_id, uniqueness: { scope: :user_id })
  validate(:validate_staff_user_not_blocking_messages)
  validate(:validate_target_valid)

  def validate_target_valid
    return if target_id.blank?
    if target_id == user_id
      errors.add(:base, "You cannot block yourself")
      throw(:abort)
    end

    if target.is_staff? && disable_messages?
      errors.add(:base, "You cannot block messages from staff members")
      throw(:abort)
    end
  end

  def validate_staff_user_not_blocking_messages
    if user.is_staff? && disable_messages?
      errors.add(:base, "You cannot block messages")
      throw(:abort)
    end
  end

  def self.available_includes
    %i[target user]
  end

  def visible?(user)
    user.is_admin? || user_id == user.id
  end
end
