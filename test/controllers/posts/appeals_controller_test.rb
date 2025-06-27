# frozen_string_literal: true

require("test_helper")

module Posts
  class AppealsControllerTest < ActionDispatch::IntegrationTest
    context("The post appeals controller") do
      setup do
        @admin = create(:admin_user)
        @appeal = create(:post_appeal)
        @post = create(:post, is_deleted: true)
      end

      context("index action") do
        should("render") do
          get(post_appeals_path)
          assert_response(:success)
        end

        should("restrict access") do
          assert_access(User::Levels::ANONYMOUS) { |user| get_auth(post_appeals_path, user) }
        end
      end

      context("new action") do
        should("render") do
          get_auth(new_post_appeal_path, @admin, params: { post_appeal: { post_id: @appeal.id } })
          assert_response(:success)
        end

        should("restrict access") do
          assert_access(User::Levels::MEMBER) { |user| get_auth(new_post_appeal_path, user, params: { post_appeal: { post_id: @appeal.id } }) }
        end
      end

      context("create action") do
        should("work") do
          assert_difference("PostEvent.count", 1) do
            post_auth(post_appeals_path, @admin, params: { post_appeal: { post_id: @post.id } })
            assert_redirected_to(post_path(@post))
          end
          assert(@post.reload.is_appealed?)
          assert_equal("appeal_created", PostEvent.last.action)
        end

        should("restrict access") do
          assert_access(User::Levels::MEMBER, success_response: :redirect) { |user| post_auth(post_appeals_path, user, params: { post_appeal: { post_id: create(:post, is_deleted: true).id } }) }
        end
      end

      context("destroy action") do
        should("work") do
          @appeal = create(:post_appeal, post: @post)
          assert_difference("PostEvent.count", 1) do
            delete_auth(post_appeal_path(@appeal), create(:janitor_user))
            assert_redirected_to(post_path(@post))
          end
          assert(@post.reload.is_deleted?)
          assert_not(@post.reload.is_appealed?)
          assert_equal("appeal_rejected", PostEvent.last.action)
          assert_equal(true, @appeal.creator.notifications.appeal_reject.exists?)
        end

        should("restrict access") do
          @appeals = create_list(:post_appeal, User::Levels.constants.length)
          assert_access([User::Levels::JANITOR, User::Levels::ADMIN, User::Levels::OWNER], success_response: :redirect) { |user| delete_auth(post_appeal_path(@appeals.shift), user) }
        end
      end

      context("accepting") do
        should("work") do
          @appeal = create(:post_appeal, post: @post)
          assert_difference("PostEvent.count", 2) do
            put_auth(undelete_post_path(@post), @admin)
            assert_redirected_to(post_path(@post))
          end
          assert(@post.reload.is_active?)
          assert_not(@post.reload.is_appealed?)
          assert_equal(%w[undeleted appeal_accepted], PostEvent.last(2).map(&:action))
          assert_equal(true, @appeal.creator.notifications.appeal_accept.exists?)
        end

        should("restrict access") do
          @appeals = create_list(:post_appeal, User::Levels.constants.length)
          assert_access([User::Levels::JANITOR, User::Levels::ADMIN, User::Levels::OWNER], success_response: :redirect) { |user| put_auth(undelete_post_path(@appeals.shift.post), user) }
        end
      end
    end
  end
end
