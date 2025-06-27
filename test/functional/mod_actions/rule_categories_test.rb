# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class RuleCategoriesTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for rule categories") do
      setup do
        @category = create(:rule_category, creator: @admin)
        set_count!
      end

      should("format rule_category_create correctly") do
        @category = create(:rule_category, creator: @admin)

        assert_matches(
          actions: %w[rule_category_create],
          text:    "Created rule category \"#{@category.name}\"",
          subject: @category,
          name:    @category.name,
        )
      end

      should("format rule_category_delete correctly") do
        @category.destroy_with(@admin)

        assert_matches(
          actions: %w[rule_category_delete],
          text:    "Deleted rule category \"#{@category.name}\"",
          subject: @category,
          name:    @category.name,
        )
      end

      should("format rule_categories_reorder correctly") do
        RuleCategory.log_reorder(2, @admin)

        assert_matches(
          actions: %w[rule_categories_reorder],
          text:    "Changed the order of 2 rule categories",
          subject: nil,
          total:   2,
        )
      end

      context("rule_category_update") do
        setup do
          @original = @category.dup
        end

        should("format name changes correctly") do
          @category.update_with!(@admin, name: "aaa")

          assert_matches(
            actions:  %w[rule_category_update],
            text:     <<~TEXT.strip,
              Updated rule category "#{@category.name}"
              Changed name from "#{@original.name}" to "#{@category.name}"
            TEXT
            subject:  @rule,
            old_name: @original.name,
            name:     @category.name,
          )
        end
      end
    end
  end
end
