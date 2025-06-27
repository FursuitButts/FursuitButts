# frozen_string_literal: true

FactoryBot.define do
  factory(:ban) do |_f|
    association(:banner, factory: :admin_user)
    association(:user, factory: :user)
    sequence(:reason) { |n| "ban_reason_#{n}" }
    duration { 60 }
  end
end
