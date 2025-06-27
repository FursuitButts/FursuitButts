# frozen_string_literal: true

FactoryBot.define do
  factory(:comment_vote) do
    association(:user)
    score { 1 }
  end
end
