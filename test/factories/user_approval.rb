# frozen_string_literal: true

FactoryBot.define do
  factory(:user_approval) do
    association(:user, factory: :restricted_user)
  end
end
