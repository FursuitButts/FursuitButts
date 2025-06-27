# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class CommentsTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for comments") do
      setup do
        @comment = create(:comment, creator: @user)
        set_count!
      end

      should("format comment_delete correctly") do
        @comment.destroy_with(@admin)

        assert_matches(
          actions: %w[comment_delete],
          text:    "Deleted comment ##{@comment.id} by #{user(@user)} on post ##{@comment.post_id}",
          subject: @comment,
          user_id: @user.id,
          post_id: @comment.post_id,
        )
      end

      should("format comment_hide correctly") do
        @comment.hide!(@admin)

        assert_matches(
          actions: %w[comment_hide],
          text:    "Hid comment ##{@comment.id} by #{user(@user)}",
          subject: @comment,
          user_id: @user.id,
        )
      end

      should("format comment_unhide correctly") do
        @comment.update_columns(is_hidden: true)
        @comment.unhide!(@admin)

        assert_matches(
          actions: %w[comment_unhide],
          text:    "Unhid comment ##{@comment.id} by #{user(@user)}",
          subject: @comment,
          user_id: @user.id,
        )
      end

      should("format comment_update correctly") do
        @original = @comment.dup
        @comment.update_with!(@admin, body: "xxx")

        assert_matches(
          actions: %w[comment_update],
          text:    "Edited comment ##{@comment.id} by #{user(@user)}",
          subject: @comment,
          user_id: @user.id,
        )
      end
    end
  end
end
