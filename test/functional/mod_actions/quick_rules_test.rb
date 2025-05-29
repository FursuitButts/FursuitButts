# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class QuickRulesTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for quick rules") do
      setup do
        @quick = create(:quick_rule)
        @rule = @quick.rule
        set_count!
      end

      context("quick_rule_create") do
        should("format with reason correctly") do
          @quick = create(:quick_rule, rule: @rule)

          assert_matches(
            actions: %w[quick_rule_create],
            text:    "Created quick rule with reason: #{@quick.reason}",
            subject: @quick,
            reason:  @quick.reason,
            header:  @quick.header,
          )
        end

        should("format with header correctly") do
          @quick = create(:quick_rule, rule: @rule, header: "header")

          assert_matches(
            actions: %w[quick_rule_create],
            text:    "Created quick rule \"#{@quick.header}\" with reason: #{@quick.reason}",
            subject: @quick,
            reason:  @quick.reason,
            header:  @quick.header,
          )
        end
      end

      context("quick_rule_delete") do
        should("format with reason correctly") do
          @quick.destroy

          assert_matches(
            actions: %w[quick_rule_delete],
            text:    "Deleted quick rule with reason: #{@quick.reason}",
            subject: @quick,
            reason:  @quick.reason,
            header:  @quick.header,
          )
        end

        should("format with header correctly") do
          @quick.update_columns(header: "Test")
          @quick.destroy

          assert_matches(
            actions: %w[quick_rule_delete],
            text:    "Deleted quick rule \"#{@quick.header}\"",
            subject: @quick,
            reason:  @quick.reason,
            header:  @quick.header,
          )
        end
      end

      should("format quick_rules_reorder correctly") do
        QuickRule.log_reorder(2)

        assert_matches(
          actions: %w[quick_rules_reorder],
          text:    "Changed the order of 2 quick rules",
          subject: nil,
          total:   2,
        )
      end

      context("quick_rule_update") do
        setup do
          @original = @quick.dup
        end

        should("format reason changes correctly") do
          @quick.update!(reason: "aaa")

          assert_matches(
            actions:    %w[quick_rule_update],
            text:       <<~TEXT.strip,
              Updated quick rule
              Changed reason from "#{@original.reason}" to "#{@quick.reason}"
            TEXT
            subject:    @quick,
            old_reason: @original.reason,
            reason:     @quick.reason,
            old_header: @original.header,
            header:     @quick.header,
          )
        end

        should("format header changes correctly") do
          @quick.update!(header: "aaa")

          assert_matches(
            actions:    %w[quick_rule_update],
            text:       <<~TEXT.strip,
              Updated quick rule
              Changed header from "#{@original.header}" to "#{@quick.header}"
            TEXT
            subject:    @quick,
            old_reason: @original.reason,
            reason:     @quick.reason,
            old_header: @original.header,
            header:     @quick.header,
          )
        end

        should("format all changes correctly") do
          @quick.update!(reason: "aaa", header: "bbb")

          assert_matches(
            actions:    %w[quick_rule_update],
            text:       <<~TEXT.strip,
              Updated quick rule
              Changed reason from "#{@original.reason}" to "#{@quick.reason}"
              Changed header from "#{@original.header}" to "#{@quick.header}"
            TEXT
            subject:    @quick,
            old_reason: @original.reason,
            reason:     @quick.reason,
            old_header: @original.header,
            header:     @quick.header,
          )
        end
      end
    end
  end
end
