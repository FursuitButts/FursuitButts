# frozen_string_literal: true

require("test_helper")

class BulkUpdateRequestsControllerTest < ActionDispatch::IntegrationTest
  context("BulkUpdateRequestsController") do
    setup do
      @user = create(:user)
      @admin = create(:admin_user)
    end

    context("new action") do
      should("render") do
        get_auth(new_bulk_update_request_path, @user)
        assert_response(:success)
      end

      should("restrict access") do
        assert_access(User::Levels::MEMBER) { |user| get_auth(new_bulk_update_request_path, user) }
      end
    end

    context("create action") do
      should("work") do
        assert_difference("BulkUpdateRequest.count", 1) do
          post_auth(bulk_update_requests_path, @user, params: { bulk_update_request: { script: "alias aaa -> bbb", title: "xxx", reason: "xxxxx" } })
        end
      end

      should("restrict access") do
        assert_access(User::Levels::MEMBER, success_response: :redirect) { |user| post_auth(bulk_update_requests_path, user, params: { bulk_update_request: { script: "alias aaa -> bbb", title: "xxx", reason: "xxxxx" } }) }
      end
    end

    context("update action") do
      setup do
        @bulk_update_request = create(:bulk_update_request, creator: @user)
      end

      should("work") do
        create(:tag, name: "zzz")
        put_auth(bulk_update_request_path(@bulk_update_request.id), @user, params: { bulk_update_request: { script: "alias zzz -> 222" } })
        @bulk_update_request.reload
        assert_equal("alias zzz -> 222", @bulk_update_request.script)
      end

      should("restrict access") do
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| put_auth(bulk_update_request_path(@bulk_update_request), user, params: { bulk_update_request: { script: "alias xxx -> 333" } }) }
      end
    end

    context("index action") do
      setup do
        @bulk_update_request = create(:bulk_update_request, creator: @user)
      end

      should("render") do
        get(bulk_update_requests_path)
        assert_response(:success)
      end

      should("restrict access") do
        assert_access(User::Levels::ANONYMOUS) { |user| get_auth(bulk_update_requests_path, user) }
      end
    end

    context("destroy action") do
      setup do
        @bulk_update_request = create(:bulk_update_request, creator: @user)
      end

      context("for the creator") do
        should("succeed") do
          delete_auth(bulk_update_request_path(@bulk_update_request), @user)
          @bulk_update_request.reload
          assert_equal("rejected", @bulk_update_request.status)
        end
      end

      context("for another member") do
        setup do
          @another_user = create(:user)
        end

        should("fail") do
          assert_difference("BulkUpdateRequest.count", 0) do
            delete_auth(bulk_update_request_path(@bulk_update_request), @another_user)
          end
        end
      end

      context("for an admin") do
        should("succeed") do
          delete_auth(bulk_update_request_path(@bulk_update_request), @admin)
          @bulk_update_request.reload
          assert_equal("rejected", @bulk_update_request.status)
        end
      end

      should("restrict access") do
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| delete_auth(bulk_update_request_path(create(:bulk_update_request, skip_forum: true)), user) }
      end
    end

    context("approve action") do
      setup do
        @bulk_update_request = create(:bulk_update_request, creator: @user)
      end

      context("for a member") do
        should("fail") do
          post_auth(approve_bulk_update_request_path(@bulk_update_request), @user, params: { format: :json })
          assert_response(:forbidden)
          @bulk_update_request.reload
          assert_equal("pending", @bulk_update_request.status)
        end
      end

      context("for an admin") do
        should("succeed") do
          post_auth(approve_bulk_update_request_path(@bulk_update_request), @admin, params: { format: :json })
          assert_response(:success)
          @bulk_update_request.reload
          assert_equal("queued", @bulk_update_request.status)
          perform_enqueued_jobs(only: ProcessBulkUpdateRequestJob)
          @bulk_update_request.reload
          assert_equal("approved", @bulk_update_request.status)
        end

        should("not succeed if its estimated count is greater than allowed") do
          Config.stubs(:get_user).with(:tag_change_request_update_limit, @admin).returns(1)
          create_list(:post, 2, tag_string: "aaa")
          post_auth(approve_bulk_update_request_path(@bulk_update_request), @admin, params: { format: :json })
          assert_response(:forbidden)
          @bulk_update_request.reload
          assert_equal("pending", @bulk_update_request.status)
        end
      end

      should("restrict access") do
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| post_auth(approve_bulk_update_request_path(create(:bulk_update_request, skip_forum: true)), user) }
      end
    end

    context("revert action") do
      setup do
        @bulk_update_request = create(:bulk_update_request, creator: @user)
        @bulk_update_request.update_with(@user, script: "alias foo -> bar")
      end

      should("revert to a previous version") do
        version = @bulk_update_request.versions.first
        assert_match(/\Aalias aaa -> bbb/, version.script)
        put_auth(revert_bulk_update_request_path(@bulk_update_request), @user, params: { version_id: version.id })
        assert_match(/\Aalias aaa -> bbb/, @bulk_update_request.reload.script)
      end

      should("not allow reverting to a previous version of another bulk_update_request") do
        @bulk_update_request2 = create(:bulk_update_request)
        put_auth(revert_bulk_update_request_path(@bulk_update_request), @user, params: { version_id: @bulk_update_request2.versions.first.id })
        @bulk_update_request.reload
        assert_not_equal(@bulk_update_request.title, @bulk_update_request2.title)
        assert_response(:missing)
      end

      should("restrict access") do
        assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| put_auth(revert_bulk_update_request_path(@bulk_update_request), user, params: { version_id: @bulk_update_request.versions.first.id }) }
      end
    end
  end
end
