# frozen_string_literal: true

FactoryBot.define do
  factory(:bulk_update_request) do
    association(:creator, factory: :user)
    title { "xxx" }
    script { "alias aaa -> bbb" }
    reason { "xxxxx" }
  end
end
