# frozen_string_literal: true

FactoryBot.define do
  factory(:rule_category) do
    association(:creator, factory: :user)
    sequence(:name) { |n| "rule_category_#{n}" }
  end
end
