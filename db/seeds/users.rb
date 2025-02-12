#!/usr/bin/env ruby
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment"))
require "faker"

TOTAL = 500
STEP = TOTAL * 0.1
TOTAL.times do |i|
  puts "Creating users.. #{i}/#{TOTAL}" if i % STEP == 0
  User.create(name: Faker::Internet.username.tr(" ", "_").tr(".", "_"), email: Faker::Internet.email, password: "qwerty", password_confirmation: "qwerty", created_at: 2.weeks.ago)
end
