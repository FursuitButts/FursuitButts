# frozen_string_literal: true

FactoryBot.define do
  factory(:post_appeal) do
    creator(factory: :user)
    post(factory: :post, is_deleted: true)
  end
end
