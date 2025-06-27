# frozen_string_literal: true

FactoryBot.define do
  factory(:user_event) do
    association(:user)
    association(:user_session)
  end
end
