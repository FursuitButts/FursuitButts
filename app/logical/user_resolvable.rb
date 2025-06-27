# frozen_string_literal: true

class UserResolvable
  attr_reader(:user, :ip_addr)

  def initialize(user, ip_addr, validate: true)
    if user.is_a?(UserResolvable)
      TraceLogger.warn("UserResolvable", "Unexpectedly received UserResolvable for user argument")
      user = recursive_resolve(user)
    end
    @user = user
    ip_addr = ip_addr.to_s if ip_addr.is_a?(IPAddr)
    @ip_addr = ip_addr
    if validate
      raise(ArgumentError, "Expected User for user argument, got #{user.inspect} (#{user.class.name})") unless user.is_a?(User)
      raise(ArgumentError, "Expected String for ip_addr argument, got #{ip_addr.inspect} (#{ip_addr.class.name})") unless ip_addr.is_a?(String)
    end
  end

  alias resolve user

  def resolvable(ip_addr = nil)
    @ip_addr = ip_addr if ip_addr.present?
    self
  end

  delegate(:recursive_resolve, to: :class)
  delegate(:to_param, :serializable_hash, :as_json, :to_json, to: :user)
  delegate_missing_to(:user, allow_nil: true)

  # needed to allow passing the class around when creating records, active record attempts to call several methods on the provided record's class
  class << self
    delegate_missing_to(:User, allow_nil: false)
  end

  def self.recursive_resolve(resolvable)
    result = resolvable
    result = result.resolve while result.is_a?(UserResolvable)
    result
  end

  def ==(other)
    return other == user if other.is_a?(User)
    other.is_a?(UserResolvable) && user == other.user
  end

  def ===(other)
    (other == UserLike && user.is_a?(User)) || super
  end

  def is_a?(other)
    (other == UserLike && user.is_a?(User)) || super
  end
end
