# frozen_string_literal: true

class CurrentUser < ActiveSupport::CurrentAttributes
  attribute(:user, :ip_addr, :request, :safe_mode)

  alias safe_mode? safe_mode
  delegate(:id, to: :user, allow_nil: true)
  delegate_missing_to(:user)



  # TODO: replace with defaults with rails 7.2 upgrade
  def initialize
    super
    reset
  end

  after_reset do
    attributes[:safe_mode] = FemboyFans.config.safe_mode?
  end

  def self.scoped(user, ip_addr = "127.0.0.1", &)
    set(user: user, ip_addr: ip_addr, &)
  end

  def self.as_system(&)
    scoped(::User.system, &)
  end
end
