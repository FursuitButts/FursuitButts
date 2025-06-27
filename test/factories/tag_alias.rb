# frozen_string_literal: true

FactoryBot.define do
  factory(:tag_alias) do
    association(:creator, factory: :user)
    antecedent_name { "aaa" }
    consequent_name { "bbb" }
    status { "active" }
  end
end
