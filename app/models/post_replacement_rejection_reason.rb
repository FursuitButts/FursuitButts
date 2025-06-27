# frozen_string_literal: true

class PostReplacementRejectionReason < ApplicationRecord
  belongs_to_user(:creator, ip: true, clones: :updater)
  belongs_to_user(:updater, ip: true)
  resolvable(:destroyer)
  validates(:reason, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false })
  validates(:order, uniqueness: true, numericality: { only_numeric: true })
  after_create(:log_create)
  after_update(:log_update)
  after_destroy(:log_delete)

  before_validation(on: :create) do
    self.order = (PostReplacementRejectionReason.maximum(:order) || 0) + 1 if order.blank?
  end

  module LogMethods
    def log_create
      ModAction.log!(creator, :post_replacement_rejection_reason_create, self,
                     reason: reason)
    end

    def log_update
      ModAction.log!(updater, :post_replacement_rejection_reason_update, self,
                     reason:     reason,
                     old_reason: reason_before_last_save)
    end

    def log_delete
      ModAction.log!(destroyer, :post_replacement_rejection_reason_delete, self,
                     reason:  reason,
                     user_id: creator_id)
    end
  end

  module SearchMethods
    def quick_access
      where.not(title: nil, prompt: nil).order(id: :desc)
    end
  end

  include(LogMethods)
  extend(SearchMethods)

  def self.log_reorder(changes, user)
    ModAction.log!(user, :post_replacement_rejection_reasons_reorder, nil, total: changes)
  end

  def self.available_includes
    %i[creator]
  end

  def visible?(user)
    user.is_approver?
  end
end
