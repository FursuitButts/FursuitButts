# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class RulesTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for rules") do
      setup do
        @category = create(:rule_category)
        @rule = create(:rule, category: @category)
        set_count!
      end

      should("format rule_create correctly") do
        @rule = create(:rule, category: @category)

        assert_matches(
          actions:       %w[rule_create],
          text:          <<~TEXT.strip,
            Created rule "#{@rule.name}" in category "#{@rule.category.name}" with description:
            [section=Rule Description]#{@rule.description}[/section]
          TEXT
          subject:       @rule,
          name:          @rule.name,
          description:   @rule.description,
          category_name: @rule.category.name,
        )
      end

      should("format rule_delete correctly") do
        @rule.destroy

        assert_matches(
          actions:       %w[rule_delete],
          text:          "Deleted rule \"#{@rule.name}\" in category \"#{@rule.category.name}\"",
          subject:       @rule,
          name:          @rule.name,
          category_name: @rule.category.name,
        )
      end

      should("format rules_reorder correctly") do
        Rule.log_reorder(2)

        assert_matches(
          actions: %w[rules_reorder],
          text:    "Changed the order of 2 rules",
          subject: nil,
          total:   2,
        )
      end

      context("rule_update") do
        setup do
          @original = @rule.dup
        end

        should("format name changes correctly") do
          @rule.update!(name: "aaa")

          assert_matches(
            actions:           %w[rule_update],
            text:              <<~TEXT.strip,
              Updated rule "#{@rule.name}" in category "#{@rule.category.name}"
              Changed name from "#{@original.name}" to "#{@rule.name}"
            TEXT
            subject:           @rule,
            old_name:          @original.name,
            name:              @rule.name,
            old_description:   @original.description,
            description:       @rule.description,
            old_category_name: @original.category.name,
            category_name:     @rule.category.name,
          )
        end

        should("format description changes correctly") do
          @rule.update!(description: "aaa")

          assert_matches(
            actions:           %w[rule_update],
            text:              <<~TEXT.strip,
              Updated rule "#{@rule.name}" in category "#{@rule.category.name}"
              Changed description: [section=Old]#{@original.description}[/section] [section=New]#{@rule.description}[/section]
            TEXT
            subject:           @rule,
            old_name:          @original.name,
            name:              @rule.name,
            old_description:   @original.description,
            description:       @rule.description,
            old_category_name: @original.category.name,
            category_name:     @rule.category.name,
          )
        end

        should("format category changes correctly") do
          @category = create(:rule_category)
          set_count!
          @rule.update!(category: @category)

          assert_matches(
            actions:           %w[rule_update],
            text:              <<~TEXT.strip,
              Updated rule "#{@rule.name}" in category "#{@rule.category.name}"
              Changed category from "#{@original.category.name}" to "#{@rule.category.name}"
            TEXT
            subject:           @rule,
            old_name:          @original.name,
            name:              @rule.name,
            old_description:   @original.description,
            description:       @rule.description,
            old_category_name: @original.category.name,
            category_name:     @rule.category.name,
          )
        end

        should("format all changes correctly") do
          @category = create(:rule_category)
          set_count!
          @rule.update!(name: "aaa", description: "bbb", category: @category)

          assert_matches(
            actions:           %w[rule_update],
            text:              <<~TEXT.strip,
              Updated rule "#{@rule.name}" in category "#{@rule.category.name}"
              Changed name from "#{@original.name}" to "#{@rule.name}"
              Changed description: [section=Old]#{@original.description}[/section] [section=New]#{@rule.description}[/section]
              Changed category from "#{@original.category.name}" to "#{@rule.category.name}"
            TEXT
            subject:           @rule,
            old_name:          @original.name,
            name:              @rule.name,
            old_description:   @original.description,
            description:       @rule.description,
            old_category_name: @original.category.name,
            category_name:     @rule.category.name,
          )
        end
      end
    end
  end
end
