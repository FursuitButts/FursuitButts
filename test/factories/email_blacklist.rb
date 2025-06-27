# frozen_string_literal: true

FactoryBot.define do
  factory(:email_blacklist) do
    association(:creator, factory: :admin_user)
    domain { "example.com" }
    reason { "xxx" }
  end
end
