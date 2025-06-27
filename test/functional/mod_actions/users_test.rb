# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class UsersTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for users") do
      setup do
        @target = create(:user, resolvable: false)
        @restricted = create(:restricted_user)
        @original = @target.dup
        set_count!
      end

      should("format user_approve correctly") do
        @approval = create(:user_approval, user: @restricted)
        @approval.approve!(@admin)

        assert_matches(
          actions: %w[user_approve],
          text:    "Approved #{user(@restricted)}",
          subject: @approval,
          user_id: @restricted.id,
        )
      end

      should("format user_blacklist_change correctly") do
        @target.update_with!(@admin, is_admin_edit: true, blacklisted_tags: "aaa bbb")

        assert_matches(
          actions: %w[user_blacklist_change],
          text:    "Edited blacklist of #{user(@target)}",
          subject: @target,
          user_id: @target.id,
        )
      end

      should("format user_ban correctly") do
        @target.ban!(@admin)

        assert_matches(
          actions: %w[user_ban],
          text:    "Banned #{user(@target)}",
          subject: @target,
          user_id: @target.id,
        )
      end

      should("format user_delete correctly") do
        UserDeletion.new(@target.resolvable("127.0.0.1"), nil, mock_request).send(:create_mod_action)

        assert_matches(
          actions: %w[user_delete],
          text:    "Deleted user #{user(@target)}",
          creator: @target,
          subject: @target,
          user_id: @target.id,
        )
      end

      should("format user_flags_change correctly") do
        @target.admin_edit!(@admin, @admin.ip_addr, unrestricted_uploads: true)

        assert_matches(
          actions: %w[user_flags_change],
          text:    "Changed #{user(@target)} flags. Added: [unrestricted uploads] Removed: []",
          subject: @target,
          user_id: @target.id,
          added:   ["unrestricted uploads"],
          removed: [],
        )
      end

      should("format user_level_change correctly") do
        @target.admin_edit!(@admin, @admin.ip_addr, level: User::Levels::TRUSTED)

        assert_matches(
          actions:   %w[user_level_change],
          text:      "Changed #{user(@target)} level from #{@original.level_string} to #{@target.level_string}",
          subject:   @target,
          user_id:   @target.id,
          old_level: @original.level_string,
          level:     @target.level_string,
        )
      end

      should("format user_name_change correctly") do
        @target.log_name_change(@admin)

        assert_matches(
          actions: %w[user_name_change],
          text:    "Changed name of #{user(@target)}",
          subject: @target,
          user_id: @target.id,
        )
      end

      should("format user_reject correctly") do
        @approval = create(:user_approval, user: @restricted)
        @approval.reject!(@admin)

        assert_matches(
          actions: %w[user_reject],
          text:    "Rejected #{user(@restricted)}",
          subject: @approval,
          user_id: @restricted.id,
        )
      end

      should("format user_text_change correctly") do
        @target.update_with!(@admin, is_admin_edit: true, profile_about: "xxx")

        assert_matches(
          actions: %w[user_text_change],
          text:    "Edited profile text of #{user(@target)}",
          subject: @target,
          user_id: @target.id,
        )
      end

      should("format user_upload_limit_change correctly") do
        @target.update_with!(@admin, is_admin_edit: true, base_upload_limit: 20)

        assert_matches(
          actions:          %w[user_upload_limit_change],
          text:             "Changed upload limit of #{user(@target)} from #{@original.base_upload_limit} to #{@target.base_upload_limit}",
          subject:          @target,
          user_id:          @target.id,
          old_upload_limit: @original.base_upload_limit,
          upload_limit:     @target.base_upload_limit,
        )
      end

      should("format user_unban correctly") do
        @target.ban!(@admin)
        set_count!
        @target.unban!(@admin)

        assert_matches(
          actions: %w[user_unban],
          text:    "Unbanned #{user(@target)}",
          subject: @target,
          user_id: @target.id,
        )
      end
    end
  end
end
