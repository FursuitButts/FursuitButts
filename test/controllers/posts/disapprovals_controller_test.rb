# frozen_string_literal: true

require("test_helper")

module Posts
  class DisapprovalsControllerTest < ActionDispatch::IntegrationTest
    context("The post disapprovals controller") do
      setup do
        @user = create(:user)
        @admin = create(:admin_user)
        @post = create(:post, is_pending: true)
      end

      context("create action") do
        should("render") do
          assert_difference("PostDisapproval.count", 1) do
            post_auth(post_disapprovals_path, @admin, params: { post_disapproval: { post_id: @post.id, reason: "borderline_quality" }, format: :json })
            assert_response(:success)
          end
        end

        should("restrict access") do
          assert_access([User::Levels::JANITOR, User::Levels::ADMIN, User::Levels::OWNER], anonymous_response: :forbidden) { |user| post_auth(post_disapprovals_path, user, params: { post_disapproval: { post_id: @post.id, reason: "borderline_quality" }, format: :json }) }
        end
      end

      context("index action") do
        should("render") do
          create(:post_disapproval, post: @post)
          get_auth(post_disapprovals_path, @admin)

          assert_response(:success)
        end

        should("restrict access") do
          assert_access([User::Levels::JANITOR, User::Levels::ADMIN, User::Levels::OWNER]) { |user| get_auth(post_disapprovals_path, user) }
        end
      end
    end
  end
end
