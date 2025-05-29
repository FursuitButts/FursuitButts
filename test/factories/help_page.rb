# frozen_string_literal: true

FactoryBot.define do
  factory(:help_page) do
    sequence(:name) { |n| "help_page_#{n}" }
    association(:wiki_page, factory: :wiki_page)
  end
end
