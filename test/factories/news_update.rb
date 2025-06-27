# frozen_string_literal: true

FactoryBot.define do
  factory(:news_update) do
    association(:creator, factory: :user)
    message { "xxx" }
  end
end
