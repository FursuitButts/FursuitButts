# frozen_string_literal: true

FactoryBot.define do
  factory(:artist) do
    association(:creator, factory: :user)
    sequence(:name) { |n| "artist_#{n}" }
  end
end
