# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module ModActions
  class ForumPostsTest < ActiveSupport::TestCase
    include(Helper)
    include(Rails.application.routes.url_helpers)

    context("mod actions for forum posts") do
      setup do
        as(@user) do
          @topic = create(:forum_topic)
          @post = create(:forum_post, topic: @topic)
        end
        set_count!
      end

      should("format forum_post_delete correctly") do
        @post.destroy

        assert_matches(
          actions:        %w[forum_post_delete],
          text:           "Deleted forum ##{@post.id} in topic ##{@topic.id} by #{user(@user)}",
          subject:        @post,
          forum_topic_id: @topic.id,
          user_id:        @user.id,
        )
      end

      should("format forum_post_hide correctly") do
        @post.hide!

        assert_matches(
          actions:        %w[forum_post_hide],
          text:           "Hid forum ##{@post.id} in topic ##{@topic.id} by #{user(@user)}",
          subject:        @post,
          forum_topic_id: @topic.id,
          user_id:        @user.id,
        )
      end

      should("format forum_post_unhide correctly") do
        @post.update_columns(is_hidden: true)
        @post.unhide!

        assert_matches(
          actions:        %w[forum_post_unhide],
          text:           "Unhid forum ##{@post.id} in topic ##{@topic.id} by #{user(@user)}",
          subject:        @post,
          forum_topic_id: @topic.id,
          user_id:        @user.id,
        )
      end

      should("format forum_post_update correctly") do
        @original = @post.dup
        @post.update!(body: "xxx")

        assert_matches(
          actions:        %w[forum_post_update],
          text:           "Edited forum ##{@post.id} in topic ##{@topic.id} by #{user(@user)}",
          subject:        @post,
          forum_topic_id: @topic.id,
          user_id:        @user.id,
        )
      end
    end
  end
end
