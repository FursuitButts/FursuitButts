# frozen_string_literal: true

FactoryBot.define do
  factory(:post_vote) do
    association(:user)
    association(:post)
    score { 1 }
  end
end
