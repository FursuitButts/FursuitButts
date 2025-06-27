# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class WikiPagesTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for wiki pages") do
      setup do
        @wiki = create(:wiki_page)
        set_count!
      end

      should("format wiki_page_delete correctly") do
        @wiki.destroy_with(@admin)

        assert_matches(
          actions:         %w[wiki_page_delete],
          text:            "Deleted wiki page [[#{@wiki.title}]]",
          subject:         @wiki,
          wiki_page_title: @wiki.title,
        )
      end

      should("format wiki_page_protect correctly") do
        level = User::Levels::ADMIN
        @wiki.update_with!(@admin, protection_level: level)

        assert_matches(
          actions:          %w[wiki_page_protect],
          text:             "Restricted editing [[#{@wiki.title}]] to [#{User::Levels.id_to_name(level)}](/help/accounts##{User::Levels.id_to_name(level).downcase}) users",
          subject:          @wiki,
          wiki_page_title:  @wiki.title,
          protection_level: level,
        )
      end

      should("format wiki_page_merge correctly") do
        @target = create(:wiki_page)
        @wiki.merge_into!(@target, @admin)

        assert_matches(
          actions:                %w[wiki_page_merge wiki_page_delete],
          text:                   "Merged wiki page [b]#{@wiki.title}[/b] into \"#{@target.title}\":#{wiki_page_path(@target)}",
          subject:                @wiki,
          wiki_page_title:        @wiki.title,
          target_wiki_page_id:    @target.id,
          target_wiki_page_title: @target.title,
        )
      end

      should("format wiki_page_rename correctly") do
        @original = @wiki.dup
        @wiki.update_with!(@admin, title: "aaa")

        assert_matches(
          actions:         %w[wiki_page_rename],
          text:            "Renamed wiki page ([[#{@original.title}]] -> [[#{@wiki.title}]])",
          subject:         @wiki,
          old_title:       @original.title,
          wiki_page_title: @wiki.title,
        )
      end

      should("format wiki_page_unprotect correctly") do
        @wiki.update_columns(protection_level: User::Levels::ADMIN)
        @wiki.update_with!(@admin, protection_level: nil)

        assert_matches(
          actions:          %w[wiki_page_unprotect],
          text:             "Removed editing restrictions for [[#{@wiki.title}]]",
          subject:          @wiki,
          wiki_page_title:  @wiki.title,
          protection_level: nil,
        )
      end
    end
  end
end
