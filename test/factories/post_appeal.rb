# frozen_string_literal: true

FactoryBot.define do
  factory(:post_appeal) do
    association(:creator, factory: :user)
    association(:post, is_deleted: true)
  end
end
