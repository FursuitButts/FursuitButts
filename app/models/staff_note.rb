# frozen_string_literal: true

class StaffNote < ApplicationRecord
  belongs_to_user(:creator, ip: true, clones: :updater)
  belongs_to_user(:updater, ip: true)
  belongs_to_user(:user)
  soft_deletable

  validates(:body, length: { maximum: 10_000 })
  after_create(:log_create)
  after_update(:log_update)

  scope(:active, -> { where(is_deleted: false) })

  module LogMethods
    def log_create
      StaffAuditLog.log!(creator, :staff_note_create, staff_note_id: id, target_id: user_id, body: body)
    end

    def log_update
      if saved_change_to_body?
        StaffAuditLog.log!(updater, :staff_note_update, staff_note_id: id, target_id: user_id, body: body, old_body: body_before_last_save)
      end

      if saved_change_to_is_deleted?
        if is_deleted?
          StaffAuditLog.log!(updater, :staff_note_delete, staff_note_id: id, target_id: user_id)
        else
          StaffAuditLog.log!(updater, :staff_note_undelete, staff_note_id: id, target_id: user_id)
        end
      end
    end
  end

  module SearchMethods
    def search(params, user, visible: true)
      super.if(!params[:include_deleted]&.truthy? && %i[id is_deleted].none? { |key| params.key?(key) }, -> { active })
    end

    def query_dsl
      super
        .field(:body_matches, :body)
        .field(:is_deleted)
        .custom(:without_system_user, ->(q, v) { q.where.not(creator_id: User.system.id) if v&.truthy? })
        .association(:user)
    end

    def default_order
      order(id: :desc)
    end
  end

  include(LogMethods)
  extend(SearchMethods)

  def self.available_includes
    %i[creator updater user]
  end
end
