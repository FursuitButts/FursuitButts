# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class UserFeedbacksTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for user feedbacks") do
      setup do
        @feedback = create(:user_feedback, user: @user, body: "test")
        set_count!
      end

      should("format user_feedback_create correctly") do
        @feedback = create(:user_feedback, user: @user, body: "test")

        assert_matches(
          actions: %w[user_feedback_create],
          text:    "Created #{@feedback.category} record ##{@feedback.id} for #{user(@user)} with reason:\n[section=Reason]#{@feedback.body}[/section]",
          subject: @feedback,
          user_id: @user.id,
          type:    @feedback.category,
          reason:  @feedback.body,
        )
      end

      should("format user_feedback_delete correctly") do
        @feedback.update(is_deleted: true)

        assert_matches(
          actions: %w[user_feedback_delete],
          text:    "Deleted #{@feedback.category} record ##{@feedback.id} for #{user(@user)} with reason:\n[section=Reason]#{@feedback.body}[/section]",
          subject: @feedback,
          user_id: @user.id,
          type:    @feedback.category,
          reason:  @feedback.body,
        )
      end

      should("format user_feedback_undelete correctly") do
        @feedback.update_column(:is_deleted, true)
        @feedback.update(is_deleted: false)

        assert_matches(
          actions: %w[user_feedback_undelete],
          text:    "Undeleted #{@feedback.category} record ##{@feedback.id} for #{user(@user)} with reason:\n[section=Reason]#{@feedback.body}[/section]",
          subject: @feedback,
          user_id: @user.id,
          type:    @feedback.category,
          reason:  @feedback.body,
        )
      end

      should("format user_feedback_destroy correctly") do
        @feedback.destroy

        assert_matches(
          actions: %w[user_feedback_destroy],
          text:    "Destroyed #{@feedback.category} record ##{@feedback.id} for #{user(@user)} with reason:\n[section=Reason]#{@feedback.body}[/section]",
          subject: @feedback,
          user_id: @user.id,
          type:    @feedback.category,
          reason:  @feedback.body,
        )
      end

      context("user_feedback_update") do
        setup do
          @original = @feedback.dup
        end

        should("format no changes correctly") do
          @feedback.save

          assert_matches(
            actions:    %w[user_feedback_update],
            text:       "Edited record ##{@feedback.id} for #{user(@user)}",
            subject:    @feedback,
            user_id:    @user.id,
            old_type:   @original.category,
            type:       @feedback.category,
            old_reason: @original.body,
            reason:     @feedback.body,
          )
        end

        should("format type changes correctly") do
          @feedback.update!(category: "neutral")

          assert_matches(
            actions:    %w[user_feedback_update],
            text:       <<~TEXT.strip,
              Edited record ##{@feedback.id} for #{user(@user)}
              Changed type from #{@original.category} to #{@feedback.category}
            TEXT
            subject:    @feedback,
            user_id:    @user.id,
            old_type:   @original.category,
            type:       @feedback.category,
            old_reason: @original.body,
            reason:     @feedback.body,
          )
        end

        should("format reason changes correctly") do
          @feedback.update!(body: "new")

          assert_matches(
            actions:    %w[user_feedback_update],
            text:       <<~TEXT.strip,
              Edited record ##{@feedback.id} for #{user(@user)}
              Changed reason: [section=Old]#{@original.body}[/section] [section=New]#{@feedback.body}[/section]
            TEXT
            subject:    @feedback,
            user_id:    @user.id,
            old_type:   @original.category,
            type:       @feedback.category,
            old_reason: @original.body,
            reason:     @feedback.body,
          )
        end

        should("format all changes correctly") do
          @feedback.update!(category: "neutral", body: "new")

          assert_matches(
            actions:    %w[user_feedback_update],
            text:       <<~TEXT.strip,
              Edited record ##{@feedback.id} for #{user(@user)}
              Changed type from #{@original.category} to #{@feedback.category}
              Changed reason: [section=Old]#{@original.body}[/section] [section=New]#{@feedback.body}[/section]
            TEXT
            subject:    @feedback,
            user_id:    @user.id,
            old_type:   @original.category,
            type:       @feedback.category,
            old_reason: @original.body,
            reason:     @feedback.body,
          )
        end
      end
    end
  end
end
