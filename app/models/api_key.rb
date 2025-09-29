# frozen_string_literal: true

class ApiKey < ApplicationRecord
  belongs_to_user(:user)
  array_attribute(:permissions)
  array_attribute(:permitted_ip_addresses)
  resolvable(:updater)
  resolvable(:destroyer)

  before_validation(:normalize_permissions)
  validates(:name, uniqueness: { scope: :user_id }, presence: true)
  validates(:key, uniqueness: true)
  validate(:validate_permissions, if: :permissions_changed?)
  has_secure_token(:key)

  module PermissionMethods
    def has_permission?(ip, controller, action)
      ip_permitted?(ip) && action_permitted?(controller, action)
    end

    def ip_permitted?(ip)
      return true if permitted_ip_addresses.empty?
      permitted_ip_addresses.any? { |permitted_ip| ip.in?(permitted_ip) }
    end

    def action_permitted?(controller, action)
      return true if permissions.empty?

      permissions.any? do |permission|
        permission == "#{controller}:#{action}"
      end
    end

    def validate_permissions
      permissions.each do |permission|
        unless permission.in?(Permissions.list)
          errors.add(:permissions, "contains invalid permission '#{permission}'")
        end
      end
    end
  end

  module SearchMethods
    def apply_order(params)
      order_with(%i[name uses], params[:order])
    end

    def query_dsl
      super
        .association(:user)
    end
  end

  include(PermissionMethods)
  extend(SearchMethods)

  def normalize_permissions
    self.permissions = permissions.compact_blank
  end

  def pretty_permissions
    permissions.map { |perm| Permissions.route(perm) }
  end

  def visible?(user)
    user.is_owner? || user_id == user.id
  end
end
