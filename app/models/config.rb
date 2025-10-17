# frozen_string_literal: true

class Config < ApplicationRecord
  self.table_name = "config"
  validate(:singleton_instance, on: :create)
  before_update(:log_update)
  after_update(-> { Config.delete_cache })
  resolvable(:updater)

  def singleton_instance
    errors.add(:base, "Only one config record is allowed") if Config.exists?
  end

  def log_update
    data = changes
    data.delete("updated_at")
    log = StaffAuditLog.log!(updater, :config_update, data: data)
    if log.errors.any?
      Rails.logger.debug(log.errors.full_messages.inspect)
    end
  end

  def self.bypass?(option, user)
    return false unless column_names.include?("#{option}_bypass")
    user.level >= instance.public_send("#{option}_bypass")
  end

  def self.get(option)
    v = instance.public_send(option)
    return Float::INFINITY if v == -1
    v
  end

  def self.get_user(option, user)
    value = get(option)
    return nil if value.blank?
    return value unless value.is_a?(Hash)
    v = value.transform_keys(&:to_i).select { |k,| k <= user.level }.max_by(&:first)&.second || 0
    return Float::INFINITY if v == -1
    v
  end

  def self.get_with_bypass(option, user)
    return Float::INFINITY if bypass?(option, user)
    get_user(option, user)
  end

  def self.instance
    Cache.fetch("configd") do
      uncached
    end
  end

  def self.uncached
    first_or_create!
  end

  def self.delete_cache
    Cache.delete("configd")
  end

  def self.settable_columns(_user)
    columns.reject { |c| %w[id updated_at].include?(c.name) }
  end

  def ary(key)
    public_send(key).split(",").map(&:strip)
  end

  # TODO: safeguards to ensure we don't override existing methods?
  column_names.each do |column|
    define_method("#{column}?") { !!public_send(column) }
    define_singleton_method(column) { instance.public_send(column) }
    define_singleton_method("#{column}?") { !!instance.public_send(column) }
  end
end
