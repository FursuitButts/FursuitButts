# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class UploadWhitelistsTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for upload whitelists") do
      context("upload_whitelist_create") do
        context("for not hidden entries") do
          setup do
            @whitelist = create(:upload_whitelist, pattern: "*aaa*", note: "aaa")
          end

          should("format correctly for users") do
            as(@user) do
              assert_matches(
                actions: %w[upload_whitelist_create],
                text:    "Created whitelist entry '[nodtext]#{@whitelist.note}[/nodtext]'",
                subject: @whitelist,
                creator: @admin,
                hidden:  false,
                pattern: @whitelist.pattern,
                note:    @whitelist.note,
              )
            end
          end

          should("format correctly for admins") do
            as(@admin) do
              assert_matches(
                actions: %w[upload_whitelist_create],
                text:    "Created whitelist entry '[nodtext]#{@whitelist.pattern}[/nodtext]'",
                subject: @whitelist,
                creator: @admin,
                hidden:  false,
                pattern: @whitelist.pattern,
                note:    @whitelist.note,
              )
            end
          end
        end

        context("for hidden entries") do
          setup do
            @whitelist = create(:upload_whitelist, pattern: "*aaa*", note: "aaa", hidden: true)
          end

          should("format correctly for users") do
            as(@user) do
              assert_matches(
                actions: %w[upload_whitelist_create],
                text:    "Created whitelist entry",
                subject: @whitelist,
                creator: @admin,
                hidden:  true,
              )
            end
          end

          should("format correctly for admins") do
            as(@admin) do
              assert_matches(
                actions: %w[upload_whitelist_create],
                text:    "Created whitelist entry '[nodtext]#{@whitelist.pattern}[/nodtext]'",
                subject: @whitelist,
                creator: @admin,
                hidden:  true,
                pattern: @whitelist.pattern,
                note:    @whitelist.note,
              )
            end
          end
        end
      end

      context("upload_whitelist_update") do
        context("for not hidden entries") do
          setup do
            @whitelist = create(:upload_whitelist, pattern: "*aaa*", note: "aaa")
            set_count!
            @original = @whitelist.dup
            @whitelist.update!(pattern: "*bbb*")
          end

          should("format correctly for users") do
            as(@user) do
              assert_matches(
                actions:     %w[upload_whitelist_update],
                text:        "Updated whitelist entry '[nodtext]#{@whitelist.note}[/nodtext]'",
                subject:     @whitelist,
                creator:     @admin,
                hidden:      false,
                pattern:     @whitelist.pattern,
                old_pattern: @original.pattern,
                note:        @whitelist.note,
              )
            end
          end

          should("format correctly for admins") do
            as(@admin) do
              assert_matches(
                actions:     %w[upload_whitelist_update],
                text:        "Updated whitelist entry '[nodtext]#{@original.pattern}[/nodtext]' -> '[nodtext]#{@whitelist.pattern}[/nodtext]'",
                subject:     @whitelist,
                creator:     @admin,
                hidden:      false,
                pattern:     @whitelist.pattern,
                old_pattern: @original.pattern,
                note:        @whitelist.note,
              )
            end
          end
        end

        context("for hidden entries") do
          setup do
            @whitelist = create(:upload_whitelist, pattern: "*aaa*", note: "aaa", hidden: true)
            set_count!
            @original = @whitelist.dup
            @whitelist.update!(pattern: "*bbb*")
          end

          should("format correctly for users") do
            as(@user) do
              assert_matches(
                actions: %w[upload_whitelist_update],
                text:    "Updated whitelist entry",
                subject: @whitelist,
                creator: @admin,
                hidden:  true,
              )
            end
          end

          should("format correctly for admins") do
            as(@admin) do
              assert_matches(
                actions:     %w[upload_whitelist_update],
                text:        "Updated whitelist entry '[nodtext]#{@original.pattern}[/nodtext]' -> '[nodtext]#{@whitelist.pattern}[/nodtext]'",
                subject:     @whitelist,
                creator:     @admin,
                hidden:      true,
                pattern:     @whitelist.pattern,
                old_pattern: @original.pattern,
                note:        @whitelist.note,
              )
            end
          end
        end
      end

      context("upload_whitelist_delete") do
        context("for not hidden entries") do
          setup do
            @whitelist = create(:upload_whitelist, pattern: "*aaa*", note: "aaa")
            set_count!
            @whitelist.destroy
          end

          should("format correctly for users") do
            as(@user) do
              assert_matches(
                actions: %w[upload_whitelist_delete],
                text:    "Deleted whitelist entry '[nodtext]#{@whitelist.note}[/nodtext]'",
                subject: @whitelist,
                creator: @admin,
                hidden:  false,
                pattern: @whitelist.pattern,
                note:    @whitelist.note,
              )
            end
          end

          should("format correctly for admins") do
            as(@admin) do
              assert_matches(
                actions: %w[upload_whitelist_delete],
                text:    "Deleted whitelist entry '[nodtext]#{@whitelist.pattern}[/nodtext]'",
                subject: @whitelist,
                creator: @admin,
                hidden:  false,
                pattern: @whitelist.pattern,
                note:    @whitelist.note,
              )
            end
          end
        end

        context("for hidden entries") do
          setup do
            @whitelist = create(:upload_whitelist, pattern: "*aaa*", note: "aaa", hidden: true)
            set_count!
            @whitelist.destroy
          end

          should("format correctly for users") do
            as(@user) do
              assert_matches(
                actions: %w[upload_whitelist_delete],
                text:    "Deleted whitelist entry",
                subject: @whitelist,
                creator: @admin,
                hidden:  true,
              )
            end
          end

          should("format correctly for admins") do
            as(@admin) do
              assert_matches(
                actions: %w[upload_whitelist_delete],
                text:    "Deleted whitelist entry '[nodtext]#{@whitelist.pattern}[/nodtext]'",
                subject: @whitelist,
                creator: @admin,
                hidden:  true,
                pattern: @whitelist.pattern,
                note:    @whitelist.note,
              )
            end
          end
        end
      end
    end
  end
end
