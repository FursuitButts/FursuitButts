# frozen_string_literal: true

class IpBan < ApplicationRecord
  belongs_to_user(:creator, ip: true, clones: :updater)
  resolvable(:updater)
  resolvable(:destroyer)
  validates(:reason, :ip_addr, presence: true)
  validates(:ip_addr, uniqueness: true)
  validate(:validate_ip_addr)
  after_create do |rec|
    StaffAuditLog.log!(creator, :ip_ban_create, ip_addr: rec.subnetted_ip, reason: rec.reason)
    Cache.delete("ipban:#{rec.ip_addr}")
  end
  after_destroy do |rec|
    StaffAuditLog.log!(destroyer, :ip_ban_delete, ip_addr: rec.subnetted_ip, reason: rec.reason)
    Cache.delete("ipban:#{rec.ip_addr}")
  end

  def self.is_banned?(ip_addr)
    return false if ip_addr.blank?
    Cache.fetch("ipban:#{ip_addr}", expires_in: 6.hours) do
      exists?(["ip_addr >>= ?", ip_addr.to_s])
    end
  end

  def self.search(params, user)
    q = super

    if params[:ip_addr].present?
      q = q.where("ip_addr >>= ?", params[:ip_addr])
    end

    q = q.where_user(:creator_id, :banner, params)

    q = q.attribute_matches(:reason, params[:reason])

    q.apply_basic_order(params)
  end

  def validate_ip_addr
    if ip_addr.blank?
      errors.add(:ip_addr, "is invalid")
    elsif ip_addr.ipv4? && ip_addr.prefix < 24
      errors.add(:ip_addr, "may not have a subnet bigger than /24")
    elsif ip_addr.ipv6? && ip_addr.prefix < 64
      errors.add(:ip_addr, "may not have a subnet bigger than /64")
    elsif ip_addr.private? || ip_addr.loopback? || ip_addr.link_local?
      errors.add(:ip_addr, "must be a public address")
    end
  end

  def has_subnet?
    (ip_addr.ipv4? && ip_addr.prefix < 32) || (ip_addr.ipv6? && ip_addr.prefix < 128)
  end

  def subnetted_ip
    str = ip_addr.to_s
    str += "/#{ip_addr.prefix}" if has_subnet?
    str
  end

  def self.available_includes
    %i[creator]
  end

  def visible?(user)
    user.is_admin?
  end
end
