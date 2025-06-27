# frozen_string_literal: true

FactoryBot.define do
  factory(:user_feedback) do
    association(:user)
    association(:creator, factory: :moderator_user)
    category { "positive" }
    sequence(:body) { |n| "user_feedback_body_#{n}" }
  end
end
