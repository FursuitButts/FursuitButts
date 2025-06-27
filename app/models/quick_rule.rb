# frozen_string_literal: true

class QuickRule < ApplicationRecord
  validates(:order, uniqueness: true, numericality: { only_integer: true, greater_than: 0 })
  validates(:reason, length: { minimum: 3, maximum: 500 })
  validates(:header, length: { maximum: 30 })
  belongs_to(:rule)
  belongs_to_user(:creator, ip: true, clones: :updater)
  belongs_to_user(:updater, ip: true)
  resolvable(:destroyer)

  before_validation(on: :create) do
    self.order = (QuickRule.maximum(:order) || 0) + 1 if order.blank?
  end

  after_create(:log_create)
  after_update(:log_update)
  after_destroy(:log_delete)

  module LogMethods
    def log_create
      ModAction.log!(creator, :quick_rule_create, self, reason: reason, header: header)
    end

    def log_update
      return unless saved_change_to_reason? || saved_change_to_header?
      ModAction.log!(updater, :quick_rule_update, self,
                     reason:     reason,
                     old_reason: reason_before_last_save,
                     header:     header,
                     old_header: header_before_last_save)
    end

    def log_delete
      ModAction.log!(destroyer, :quick_rule_delete, self, reason: reason, header: header)
    end
  end

  include(LogMethods)

  def self.log_reorder(total, user)
    ModAction.log!(user, :quick_rules_reorder, nil, total: total)
  end

  def self.available_includes
    %i[rule]
  end
end
