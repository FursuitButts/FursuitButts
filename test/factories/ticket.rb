# frozen_string_literal: true

FactoryBot.define do
  factory(:ticket) do
    association(:creator, factory: :user)
    reason { "test" }
  end
end
