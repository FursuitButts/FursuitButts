#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "base"

PASSWORD = "qwerty"
TOTAL = 500
UNVERIFIED_COUNT = TOTAL * 0.01 # 1%
RESTRICTED_COUNT = TOTAL * 0.1  # 10%
STEP = TOTAL * 0.1
unverified = TOTAL.times.to_a.sample(UNVERIFIED_COUNT)
restricted = (TOTAL.times.to_a - unverified).sample(RESTRICTED_COUNT)
TOTAL.times do |i|
  puts "Creating users.. #{i + 1}/#{TOTAL}" if (i + 1) % STEP == 0 || (i + 1) == TOTAL
  User.create(name: Faker::Internet.username.tr(" ", "_").tr(".", "_"), email: Faker::Internet.email, password: PASSWORD, password_confirmation: PASSWORD, created_at: 2.weeks.ago, email_verified: unverified.exclude?(i), level: (restricted.include?(i) ? User::Levels::RESTRICTED : User::Levels::MEMBER))
end
