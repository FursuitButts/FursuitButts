#!/usr/bin/env ruby
# frozen_string_literal: true

require(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "config", "environment")))

ModAction.find_each do |p|
  p.values = p.values_old
  p.save!(validate: false)
rescue Encoding::UndefinedConversionError
  # Interacting with the model at all throws the exception again. Yay rails.
rescue StandardError
  puts("#{p.id} has an exception")
end
