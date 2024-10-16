# frozen_string_literal: true

class UserApproval < ApplicationRecord
  class ValidationError < StandardError; end
  belongs_to_updater optional: true
  belongs_to :user
  enum status: {
    pending:  "pending",
    approved: "approved",
    rejected: "rejected",
  }

  module SearchMethods
    def search(params)
      q = super

      q = q.where_user(:user_id, :user, params)
      q = q.where_user(:updater_id, :updater, params)
      q = q.where(status: params[:status]) if params[:status].present?

      q.apply_basic_order(params)
    end
  end

  module UpdateMethods
    def is_approvable?
      return false if user.is_banned? || status == "approved"
      return true if user.is_restricted? || user.is_rejected?
      false
    end

    def is_rejectable?
      (user.is_restricted? && status != "approved") || (user.level == User::Levels::MEMBER && status == "approved")
    end

    def approve!
      errors.add(:user, "is not approvable") unless is_approvable?
      return if errors.any?

      update(status: "approved")
      user.update(level: User::Levels::MEMBER)
      Dmail.create_automated(to: user, title: "Your account has been approved", body: "Your account has been approved by \"#{CurrentUser.name}\":/users/#{CurrentUser.id}. You can now use the site normally.")
      ModAction.log!(:user_approve, self, user_id: user.id)
    end

    def reject!
      errors.add(:user, "is not rejectable") unless is_rejectable?
      return if errors.any?

      update(status: "rejected")
      user.update(level: User::Levels::REJECTED)
      Dmail.create_automated(to: user, title: "Your account has been rejected", body: "Your account has been rejected by \"#{CurrentUser.name}\":/users/#{CurrentUser.id}. For more details, \"contact them\":/dmails/new?dmail[to_id]=#{CurrentUser.id}.")
      ModAction.log!(:user_reject, self, user_id: user.id)
    end
  end

  include UpdateMethods
  extend SearchMethods
end
