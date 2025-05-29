# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class CommentsTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for comments") do
      setup do
        as(@user) do
          @comment = create(:comment)
        end
        set_count!
      end

      should("format comment_delete correctly") do
        @comment.destroy

        assert_matches(
          actions: %w[comment_delete],
          text:    "Deleted comment ##{@comment.id} by #{user(@user)} on post ##{@comment.post_id}",
          subject: @comment,
          user_id: @user.id,
          post_id: @comment.post_id,
        )
      end

      should("format comment_hide correctly") do
        @comment.hide!

        assert_matches(
          actions: %w[comment_hide],
          text:    "Hid comment ##{@comment.id} by #{user(@user)}",
          subject: @comment,
          user_id: @user.id,
        )
      end

      should("format comment_unhide correctly") do
        @comment.update_columns(is_hidden: true)
        @comment.unhide!

        assert_matches(
          actions: %w[comment_unhide],
          text:    "Unhid comment ##{@comment.id} by #{user(@user)}",
          subject: @comment,
          user_id: @user.id,
        )
      end

      should("format comment_update correctly") do
        @original = @comment.dup
        @comment.update!(body: "xxx")

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
