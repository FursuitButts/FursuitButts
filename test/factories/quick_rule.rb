# frozen_string_literal: true

FactoryBot.define do
  factory(:quick_rule) do
    association(:creator, factory: :user)
    association(:rule)
    sequence(:reason) { |n| "quick_rule_#{n}" }
  end
end
