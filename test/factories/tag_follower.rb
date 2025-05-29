# frozen_string_literal: true

FactoryBot.define do
  factory(:tag_follower) do
    user { create(:user) }
    tag { create(:tag) }
    last_post { create(:post) }
  end
end
