# frozen_string_literal: true

FactoryBot.define do
  factory(:comment) do
    association(:creator, factory: :old_user)
    post { create(:post, creator: creator) } # fails when using association or build
    sequence(:body) { |n| "comment_body_#{n}" }
  end
end
