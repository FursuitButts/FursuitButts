# frozen_string_literal: true

FactoryBot.define do
  factory(:post_disapproval) do
    association(:user, factory: :janitor_user)
    association(:post, is_pending: true)
    reason { %w[borderline_quality borderline_relevancy other].sample }
    sequence(:message) { |n| "post_disapproval_message_#{n}" }
  end
end
