# frozen_string_literal: true

FactoryBot.define do
  factory(:forum_post_vote) do
    association(:user, factory: :user)
    score { 1 }
  end
end
