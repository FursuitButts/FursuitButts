# frozen_string_literal: true

FactoryBot.define do
  factory(:user_block) do
    association(:user)
    association(:target, factory: :user)
  end
end
