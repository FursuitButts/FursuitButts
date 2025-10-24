# frozen_string_literal: true

class BulkUpdateRequestVersion < ApplicationRecord
  belongs_to_user(:updater, ip: true)
  undoable
  belongs_to(:bulk_update_request)
  before_validation(:fill_version, on: :create)
  before_validation(:fill_changes, on: :create)

  module SearchMethods
    def default_order
      order(id: :desc)
    end

    def query_dsl
      super
        .field(:bulk_update_request_id)
        .field(:ip_addr, :updater_ip_addr)
        .association(:updater)
        .association(:bulk_update_request)
    end
  end

  extend(SearchMethods)

  def self.queue(bulk_update_request, updater)
    create({
      bulk_update_request_id: bulk_update_request.id,
      updater_id:             updater.id,
      updater_ip_addr:        updater.ip_addr,
      script:                 bulk_update_request.script,
      status:                 bulk_update_request.status,
      title:                  bulk_update_request.title,
    })
  end

  def self.calculate_version(bulk_update_request_id)
    where(bulk_update_request_id: bulk_update_request_id).maximum(:version).to_i + 1
  end

  def fill_version
    self.version = BulkUpdateRequestVersion.calculate_version(bulk_update_request_id)
  end

  def fill_changes
    self.script_changed = previous.nil? || previous.script != script
    self.status_changed = previous.nil? || previous.status != status
    self.title_changed = previous.nil? || previous.title != title
  end

  def previous
    @previous ||= BulkUpdateRequestVersion.where(bulk_update_request_id: bulk_update_request_id).where.lt(version: version).order(version: :desc).first
  end

  def changes_text
    return %w[created] if version == 1
    list = []
    list << "script" if script_changed?
    list << "status" if status_changed?
    list << "title" if title_changed?
    list
  end

  def self.available_includes
    %i[bulk_update_request updater]
  end
end
