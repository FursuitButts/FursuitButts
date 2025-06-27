# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class HelpPagesTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for help pages") do
      setup do
        @help = create(:help_page)
        set_count!
      end

      should("format help_create correctly") do
        @help = create(:help_page, creator: @admin)

        assert_matches(
          actions:         %w[help_create],
          text:            "Created help page \"#{@help.name}\":#{help_page_path(id: @help.name)} (\"#{@help.wiki_page_title}\":#{wiki_page_path(id: @help.wiki_page_id)})",
          subject:         @help,
          name:            @help.name,
          wiki_page_title: @help.wiki_page_title,
          wiki_page_id:    @help.wiki_page_id,
        )
      end

      should("format help_delete correctly") do
        @help.destroy_with(@admin)

        assert_matches(
          actions:         %w[help_delete],
          text:            "Deleted help page \"#{@help.name}\":#{help_page_path(id: @help.name)} (\"#{@help.wiki_page_title}\":#{wiki_page_path(id: @help.wiki_page_id)})",
          subject:         @help,
          name:            @help.name,
          wiki_page_title: @help.wiki_page_title,
          wiki_page_id:    @help.wiki_page_id,
        )
      end

      should("format help_update correctly") do
        @original = @help.dup
        @help.update_with!(@admin, title: "xxx")

        assert_matches(
          actions:         %w[help_update],
          text:            "Updated help page \"#{@help.name}\":#{help_page_path(id: @help.name)} (\"#{@help.wiki_page_title}\":#{wiki_page_path(id: @help.wiki_page_id)})",
          subject:         @help,
          name:            @help.name,
          wiki_page_title: @help.wiki_page_title,
          wiki_page_id:    @help.wiki_page_id,
        )
      end
    end
  end
end
