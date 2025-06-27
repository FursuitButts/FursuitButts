# frozen_string_literal: true

require("test_helper")

class MaintenanceTest < ActiveSupport::TestCase
  context("daily maintenance") do
    should("work") do
      assert_nothing_raised { Maintenance.daily }
    end
  end

  context("hourly maintenance") do
    should("work") do
      assert_nothing_raised { Maintenance.hourly }
    end
  end
end
