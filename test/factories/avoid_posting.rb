# frozen_string_literal: true

FactoryBot.define do
  factory(:avoid_posting) do
    association(:creator, factory: :owner_user)
    association(:artist)
  end
end
