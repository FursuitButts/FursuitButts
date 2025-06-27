# frozen_string_literal: true

FactoryBot.define do
  factory(:dmail) do
    association(:to, factory: :user)
    association(:from, factory: :user)
    owner { from }
    sequence(:title) { |n| "dmail_title_#{n}" }
    sequence(:body) { |n| "dmail_body_#{n}" }
  end
end
