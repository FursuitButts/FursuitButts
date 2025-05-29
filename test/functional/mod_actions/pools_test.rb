# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class PoolsTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for pools") do
      setup do
        @pool = create(:pool)
        set_count!
      end

      should("format pool_delete correctly") do
        @pool.destroy

        assert_matches(
          actions:   %w[pool_delete],
          text:      "Deleted pool ##{@pool.id} (named #{@pool.name}) by #{user(@admin)}",
          subject:   @pool,
          pool_name: @pool.name,
          user_id:   @admin.id,
        )
      end
    end
  end
end
