# frozen_string_literal: true

FactoryBot.define do
  factory(:notification) do
    association(:user)
  end
end
