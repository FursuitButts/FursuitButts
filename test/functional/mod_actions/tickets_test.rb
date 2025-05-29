# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class TicketsTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for tickets") do
      setup do
        @ticket = create(:ticket, model: @admin)
        set_count!
      end

      should("format ticket_claim correctly") do
        @ticket.claim!(@user)

        assert_matches(
          actions: %w[ticket_claim],
          text:    "Claimed ticket ##{@ticket.id}",
          subject: @ticket,
        )
      end

      should("format ticket_unclaim correctly") do
        @ticket.update_columns(claimant_id: @admin.id)
        @ticket.unclaim!

        assert_matches(
          actions: %w[ticket_unclaim],
          text:    "Unclaimed ticket ##{@ticket.id}",
          subject: @ticket,
        )
      end

      should("format ticket_update correctly") do
        @ticket.update!(response: "xxx")

        assert_matches(
          actions: %w[ticket_update],
          text:    "Modified ticket ##{@ticket.id}",
          subject: @ticket,
        )
      end
    end
  end
end
