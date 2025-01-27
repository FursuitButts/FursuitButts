# frozen_string_literal: true

require "test_helper"

module Forums
  module Posts
    class VotesControllerTest < ActionDispatch::IntegrationTest
      context "The forum post votes controller" do
        setup do
          @user = create(:user)
          as(@user) do
            @topic = create(:forum_topic, original_post_attributes: { body: "test" })
            @forum_post = @topic.original_post
            @ta = create(:tag_alias, forum_post: @forum_post, antecedent_name: "aaa", consequent_name: "bbb", status: "pending")
            @forum_post.update(tag_change_request: @ta, allow_voting: true)
            @topic2 = create(:forum_topic, original_post_attributes: { body: "test2" })
            @forum_post2 = @topic2.original_post
            @ti = create(:tag_implication, forum_post: @forum_post2, antecedent_name: "ccc", consequent_name: "ddd", status: "pending")
            @forum_post2.update(tag_change_request: @ti, allow_voting: true)
            @forum_post3 = create(:forum_post, topic: @topic, allow_voting: false)
          end

          @user2 = create(:user)
          @admin = create(:admin_user)
          CurrentUser.user = @user2
        end

        context "index action" do
          should "render" do
            get_auth url_for(controller: "forums/posts/votes", action: "index", only_path: true), @admin
            assert_response :success
          end

          context "members" do
            should "render" do
              get_auth url_for(controller: "forums/posts/votes", action: "index", only_path: true), @user2
              assert_response :success
            end

            should "only list own votes" do
              create(:forum_post_vote, forum_post: @forum_post, user: @user2, score: -1)
              create(:forum_post_vote, forum_post: @forum_post, user: @admin, score: 1)

              get_auth url_for(controller: "forums/posts/votes", action: "index", format: "json", only_path: true), @user2
              assert_response :success
              assert_equal(1, response.parsed_body.length)
              assert_equal(@user2.id, response.parsed_body[0]["user_id"])
            end
          end

          should "restrict access" do
            assert_access(User::Levels::MEMBER, anonymous_response: :forbidden) { |user| get_auth url_for(controller: "forums/posts/votes", action: "index", format: "json", only_path: true), user }
          end
        end

        context "create action" do
          should "create a vote" do
            post_auth forum_post_votes_path(@forum_post), @user2, params: { score: 1, format: :json }
            assert_response :success

            assert_equal(1, @forum_post.votes.find_by(user: @user2)&.score)
          end

          should "not allow voting if user is forbidden" do
            as(@admin) { @user2.update(no_aibur_voting: true) }
            post_auth forum_post_votes_path(@forum_post), @user2, params: { score: 1, format: :json }
            assert_response :forbidden
            assert_equal("Access Denied: You are not allowed to vote on tag change requests.", @response.parsed_body["reason"])

            assert_nil(@forum_post.votes.find_by(user: @user2))
          end

          should "not allow voting if allow_voting=false" do
            post_auth forum_post_votes_path(@forum_post3), @user2, params: { score: 1, format: :json }
            assert_response(:bad_request)
            assert_equal("Forum post does not allow votes.", @response.parsed_body["message"])

            assert_nil(@forum_post3.votes.find_by(user: @user2))
          end

          should "not allow voting on non-pending requests" do
            @ta.update_columns(status: "active")
            post_auth forum_post_votes_path(@forum_post), @user2, params: { score: 1, format: :json }
            assert_response(:forbidden)
            assert_equal("Access Denied: You cannot vote on completed tag change requests.", @response.parsed_body["reason"])

            @ti.update_columns(status: "deleted")
            post_auth forum_post_votes_path(@forum_post2), @user2, params: { score: -1, format: :json }
            assert_response(:forbidden)
            assert_equal("Access Denied: You cannot vote on completed tag change requests.", @response.parsed_body["reason"])

            assert_nil(@forum_post2.votes.find_by(user: @user2))
          end

          should "restrict access" do
            assert_access(User::Levels::MEMBER, anonymous_response: :forbidden) { |user| post_auth forum_post_votes_path(@forum_post), user, params: { score: 1, format: :json } }
          end
        end

        context "delete action" do
          setup do
            @vote = create(:forum_post_vote, forum_post: @forum_post, user: @user2, score: -1)
          end

          should "delete votes" do
            post_auth delete_forum_post_votes_path, @admin, params: { ids: @vote.id, format: :json }
            assert_response :success

            assert_raises(ActiveRecord::RecordNotFound) do
              @vote.reload
            end
          end

          should "create a staff audit log entry" do
            assert_difference("StaffAuditLog.count", 1) do
              post_auth delete_forum_post_votes_path, @admin, params: { ids: @vote.id, format: :json }
              assert_response :success

              assert_raises(ActiveRecord::RecordNotFound) do
                @vote.reload
              end
            end

            log = StaffAuditLog.last
            assert_equal "forum_post_vote_delete", log.action
            assert_equal @forum_post.id, log.forum_post_id
            assert_equal(-1, log.vote)
            assert_equal @user2.id, log.voter_id
          end

          should "restrict access" do
            @votes = []
            User::Levels.constants.length.times do
              @votes << create(:forum_post_vote, forum_post: @forum_post, user: create(:user), score: 1)
            end
            assert_access(User::Levels::ADMIN) { |user| post_auth delete_forum_post_votes_path, user, params: { ids: @votes.shift.id } }
          end
        end
      end
    end
  end
end
