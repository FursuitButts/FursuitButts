# frozen_string_literal: true

FactoryBot.define do
  factory(:post_replacement_rejection_reason) do
    association(:creator, factory: :admin_user)
    sequence(:reason) { |n| "reason_#{n}" }
  end
end
