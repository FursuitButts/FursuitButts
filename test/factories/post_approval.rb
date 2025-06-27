# frozen_string_literal: true

FactoryBot.define do
  factory(:post_approval) do
    association(:user, factory: :janitor_user)
    association(:post, is_pending: true)
  end
end
