# frozen_string_literal: true

require "test_helper"

module Forums
  module Topics
    class MergesControllerTest < ActionDispatch::IntegrationTest
      context "The forum topic merges controller" do
        setup do
          @user = create(:trusted_user, created_at: 1.month.ago)
          @admin = create(:admin_user)
          CurrentUser.user = @admin
          as(@user) do
            @topic = create(:forum_topic)
            @ogpost = @topic.original_post
            @post = create(:forum_post, topic: @topic)
            @target = create(:forum_topic)
          end
        end

        context "show action" do
          should "render" do
            get_auth merge_forum_topic_path(@topic), @admin
          end

          should "restrict access" do
            assert_access(User::Levels::MODERATOR) { |user| get_auth merge_forum_topic_path(@topic), user }
          end
        end

        context "create action" do
          should "work" do
            assert_difference({ "EditHistory.merged.count" => 2, "ModAction.count" => 1 }) do
              post_auth merge_forum_topic_path(@topic), @admin, params: { forum_topic: { target_topic_id: @target.id } }
              assert_redirected_to(forum_topic_path(@target))
            end
            assert_equal(true, @topic.reload.is_hidden?)
            assert_equal(0, @topic.posts.count)
            assert_equal(3, @target.posts.count)
            assert_equal(@target.id, @ogpost.reload.topic_id)
            assert_equal(@target.id, @post.reload.topic_id)
            assert_equal(@topic.id, @ogpost.reload.original_topic_id)
            assert_equal(@topic.id, @post.reload.original_topic_id)
            assert_equal(@target.id, @topic.reload.merge_target_id)
            assert_equal({ "old_topic_id" => @topic.id, "old_topic_title" => @topic.title, "new_topic_id" => @target.id, "new_topic_title" => @target.title }, EditHistory.last.extra_data)
            assert_equal("forum_topic_merge", ModAction.last.action)
          end

          should "restrict access" do
            @topics = create_list(:forum_topic, User::Levels.constants.length)
            assert_access(User::Levels::MODERATOR, success_response: :redirect) { |user| post_auth merge_forum_topic_path(@topics.shift), user, params: { forum_topic: { target_topic_id: @target.id } } }
          end
        end

        context "undo action" do
          setup do
            @topic.merge_into!(@target)
          end

          should "render" do
            get_auth undo_merge_forum_topic_path(@topic), @admin
          end

          should "restrict access" do
            @topics = create_list(:forum_topic, User::Levels.constants.length)
            @topics.each { |t| t.merge_into!(@target) }
            assert_access(User::Levels::MODERATOR) { |user| get_auth undo_merge_forum_topic_path(@topics.shift), user }
          end
        end

        context "destroy action" do
          setup do
            @topic.merge_into!(@target)
          end

          should "work" do
            assert_difference({ "EditHistory.unmerged.count" => 2, "ModAction.count" => 1 }) do
              delete_auth merge_forum_topic_path(@topic), @admin
              assert_redirected_to(forum_topic_path(@topic))
            end
            assert_equal(2, @topic.posts.count)
            assert_equal(1, @target.posts.count)
            assert_equal(@topic.id, @ogpost.reload.topic_id)
            assert_equal(@topic.id, @post.reload.topic_id)
            assert_nil(@ogpost.reload.original_topic_id)
            assert_nil(@post.reload.original_topic_id)
            assert_nil(@topic.reload.merge_target_id)
            assert_equal({ "old_topic_id" => @target.id, "old_topic_title" => @target.title, "new_topic_id" => @topic.id, "new_topic_title" => @topic.title }, EditHistory.last.extra_data)
            assert_equal("forum_topic_unmerge", ModAction.last.action)
          end

          should "fail gracefully if the target topic no longer exists" do
            @target.destroy!
            delete_auth merge_forum_topic_path(@topic), @admin
            assert_response(422)
          end

          should "restrict access" do
            @topics = create_list(:forum_topic, User::Levels.constants.length)
            @topics.each { |t| t.merge_into!(@target) }
            assert_access(User::Levels::MODERATOR, success_response: :redirect) { |user| delete_auth merge_forum_topic_path(@topics.shift), user }
          end
        end
      end
    end
  end
end
