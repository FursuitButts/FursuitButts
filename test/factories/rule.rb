# frozen_string_literal: true

FactoryBot.define do
  factory(:rule) do
    association(:creator, factory: :user)
    association(:category, factory: :rule_category)
    sequence(:name) { |n| "rule_#{n}" }
    sequence(:description) { |n| "rule_description_#{n}" }
  end
end
