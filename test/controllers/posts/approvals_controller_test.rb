# frozen_string_literal: true

require("test_helper")

module Posts
  class ApprovalsControllerTest < ActionDispatch::IntegrationTest
    context("The post approvals controller") do
      setup do
        @approval = create(:post_approval)
      end

      context("index action") do
        should("render") do
          get(post_approvals_path)
          assert_response(:success)
        end

        should("restrict access") do
          assert_access(User::Levels::ANONYMOUS) { |user| get_auth(post_approvals_path, user) }
        end
      end

      context("create action") do
        setup do
          @admin = create(:admin_user)
          @post = create(:post, is_pending: true)
        end

        should("work") do
          post_auth(post_approvals_path, @admin, params: { post_id: @post.id, format: :json })
          assert_response(:success)
          @post.reload
          assert_not(@post.reload.is_pending?)
          assert_equal(true, @post.uploader.notifications.post_approve.exists?)
        end

        should("restrict access") do
          assert_access([User::Levels::JANITOR, User::Levels::ADMIN, User::Levels::OWNER], anonymous_response: :forbidden) { |user| post_auth(post_approvals_path, user, params: { post_id: create(:post, is_pending: true).id, format: :json }) }
        end
      end

      context("destroy action") do
        setup do
          @admin = create(:admin_user)
          @post = create(:post, is_pending: true)
          @post.approve!(@admin)
        end

        should("work") do
          delete_auth(post_approval_path(@post), @admin, params: { format: :json })
          assert_response(:success)
          assert(@post.reload.is_pending?)
          assert_equal(true, @post.uploader.notifications.post_unapprove.exists?)
        end

        should("not work if user is not approver") do
          delete_auth(post_approval_path(@post), create(:admin_user), params: { format: :json })
          assert_response(:bad_request)
          assert_not(@post.reload.is_pending?)
        end

        should("restrict access") do
          assert_access([User::Levels::JANITOR, User::Levels::ADMIN, User::Levels::OWNER], anonymous_response: :forbidden) do |user|
            post = create(:post, is_pending: true)
            post.approve!(user)
            delete_auth(post_approval_path(post), user, params: { format: :json })
          end
        end
      end
    end
  end
end
