# frozen_string_literal: true

FactoryBot.define do
  factory(:mod_action) do
    association(:creator, factory: :user)
    action { "test" }
  end
end
