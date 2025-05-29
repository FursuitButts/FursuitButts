# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class PostReplacementRejectionReasonsTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for post replacement rejection reasons") do
      setup do
        @reason = create(:post_replacement_rejection_reason)
        set_count!
      end

      should("format post_replacement_rejection_reason_create correctly") do
        @reason = create(:post_replacement_rejection_reason)

        assert_matches(
          actions: %w[post_replacement_rejection_reason_create],
          text:    "Created post replacement rejection reason \"#{@reason.reason}\"",
          subject: @reason,
          reason:  @reason.reason,
        )
      end

      should("format post_replacement_rejection_reason_delete correctly") do
        @reason.destroy

        assert_matches(
          actions: %w[post_replacement_rejection_reason_delete],
          text:    "Deleted post replacement rejection reason \"#{@reason.reason}\" by #{user(@admin)}",
          subject: @reason,
          reason:  @reason.reason,
          user_id: @admin.id,
        )
      end

      should("format post_replacement_rejection_reasons_reorder correctly") do
        PostReplacementRejectionReason.log_reorder(2)

        assert_matches(
          actions: %w[post_replacement_rejection_reasons_reorder],
          text:    "Changed the order of 2 post replacement rejection reasons.",
          subject: nil,
          total:   2,
        )
      end

      context("post_replacement_rejection_reason_update") do
        setup do
          @original = @reason.dup
        end

        should("format no changes correctly") do
          @reason.save

          assert_matches(
            actions:    %w[post_replacement_rejection_reason_update],
            text:       "Updated post replacement rejection reason \"#{@reason.reason}\"",
            subject:    @reason,
            reason:     @reason.reason,
            old_reason: @original.reason,
          )
        end

        should("format reason changes correctly") do
          @reason.update!(reason: "xxx")

          assert_matches(
            actions:    %w[post_replacement_rejection_reason_update],
            text:       <<~TEXT.strip,
              Updated post replacement rejection reason "#{@reason.reason}"
              Changed reason from "#{@original.reason}" to "#{@reason.reason}"
            TEXT
            subject:    @reason,
            reason:     @reason.reason,
            old_reason: @original.reason,
          )
        end
      end
    end
  end
end
