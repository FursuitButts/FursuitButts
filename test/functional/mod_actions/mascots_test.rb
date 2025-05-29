# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class MascotsTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for mascots") do
      setup do
        @mascot = create(:mascot)
        set_count!
      end

      should("parse mascot_create correctly") do
        @mascot.destroy # duplicate md5 error otherwise
        set_count!
        @mascot = create(:mascot)

        assert_matches(
          actions: %w[mascot_create],
          text:    "Created mascot ##{@mascot.id}",
          subject: @mascot,
        )
      end

      should("parse mascot_delete correctly") do
        @mascot.destroy

        assert_matches(
          actions: %w[mascot_delete],
          text:    "Deleted mascot ##{@mascot.id}",
          subject: @mascot,
        )
      end

      should("parse mascot_update correctly") do
        @original = @mascot.dup
        @mascot.update!(display_name: "xxx")

        assert_matches(
          actions: %w[mascot_update],
          text:    "Updated mascot ##{@mascot.id}",
          subject: @mascot,
        )
      end
    end
  end
end
