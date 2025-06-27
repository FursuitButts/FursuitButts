# frozen_string_literal: true

FactoryBot.define do
  factory(:tag_follower) do
    association(:user)
    association(:tag)
    association(:last_post, factory: :post)
  end
end
