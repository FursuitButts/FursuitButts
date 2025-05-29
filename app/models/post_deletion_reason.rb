# frozen_string_literal: true

class PostDeletionReason < ApplicationRecord
  belongs_to_creator
  validates(:reason, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false })
  validates(:title, allow_blank: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false })
  validates(:prompt, allow_blank: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false })
  validates(:order, uniqueness: true, numericality: { only_numeric: true })
  validate(:validate_prompt_and_title)
  after_create(:log_create)
  after_update(:log_update)
  after_destroy(:log_delete)

  before_validation(on: :create) do
    self.order = (PostDeletionReason.maximum(:order) || 0) + 1 if order.blank?
  end

  def validate_prompt_and_title
    errors.add(:prompt, "is required") if prompt.blank? && title.present?
    errors.add(:title, "is required") if title.blank? && prompt.present?
  end

  module LogMethods
    def log_create
      ModAction.log!(:post_deletion_reason_create, self,
                     reason: reason,
                     title:  title,
                     prompt: prompt)
    end

    def log_update
      ModAction.log!(:post_deletion_reason_update, self,
                     reason:     reason,
                     old_reason: reason_before_last_save,
                     title:      title,
                     old_title:  title_before_last_save,
                     prompt:     prompt,
                     old_prompt: prompt_before_last_save)
    end

    def log_delete
      ModAction.log!(:post_deletion_reason_delete, self,
                     reason:  reason,
                     title:   title,
                     prompt:  prompt,
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

  def self.log_reorder(changes)
    ModAction.log!(:post_deletion_reasons_reorder, nil, total: changes)
  end

  def self.available_includes
    %i[creator]
  end

  def visible?(user = CurrentUser.user)
    user.is_approver?
  end
end
