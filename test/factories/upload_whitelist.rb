# frozen_string_literal: true

FactoryBot.define do
  factory(:upload_whitelist) do
    association(:creator, factory: :admin_user)
  end
end
