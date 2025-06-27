# frozen_string_literal: true

FactoryBot.define do
  factory(:help_page) do
    association(:creator, factory: :admin_user)
    association(:wiki_page)
    sequence(:name) { |n| "help_page_#{n}" }
  end
end
