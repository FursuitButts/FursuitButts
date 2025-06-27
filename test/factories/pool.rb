# frozen_string_literal: true

FactoryBot.define do
  factory(:pool) do
    association(:creator, factory: :user)
    sequence(:name) { |n| "pool_#{n}" }
    sequence(:description) { |n| "pool_description_#{n}" }
  end
end
