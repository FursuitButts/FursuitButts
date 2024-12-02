# frozen_string_literal: true

require "test_helper"

module Users
  class NameChangeRequestsControllerTest < ActionDispatch::IntegrationTest
    context "The user name change requests controller" do
      setup do
        @user = create(:trusted_user)
        @admin = create(:admin_user)
        as(@user) do
          @change_request = UserNameChangeRequest.create!(
            user_id:       @user.id,
            original_name: @user.name,
            desired_name:  "abc",
            change_reason: "hello",
          )
        end
      end

      context "new action" do
        should "render" do
          get_auth new_user_name_change_request_path, @user
          assert_response :success
        end

        should "restrict access" do
          assert_access(User::Levels::REJECTED) { |user| get_auth new_user_name_change_request_path, user }
        end
      end

      context "create action" do
        should "work" do
          post_auth user_name_change_requests_path, @user, params: { user_name_change_request: { desired_name: "zun" } }
          assert_response :success
        end

        should "restrict access" do
          assert_access(User::Levels::REJECTED, success_response: :redirect) { |user| post_auth user_name_change_requests_path, user, params: { user_name_change_request: { desired_name: SecureRandom.hex(6) } } }
        end
      end

      context "show action" do
        should "render" do
          get_auth user_name_change_request_path(@change_request), @user
          assert_response :success
        end

        context "when the current user is not an admin and does not own the request" do
          should "fail" do
            @another_user = create(:user)
            get_auth user_name_change_request_path(@change_request), @another_user
            assert_response :forbidden
          end
        end

        should "restrict access" do
          assert_access(User::Levels::REJECTED) do |user|
            request = UserNameChangeRequest.create!(
              user_id:       user.id,
              original_name: user.name,
              desired_name:  "user_#{SecureRandom.hex(6)}",
              change_reason: "hello",
            )
            get_auth user_name_change_request_path(request), user
          end
        end
      end

      context "for actions restricted to admins" do
        context "index action" do
          should "render" do
            get_auth user_name_change_requests_path, @admin
            assert_response :success
          end

          should "restrict access" do
            assert_access(User::Levels::MODERATOR) { |user| get_auth user_name_change_requests_path, user }
          end
        end
      end
    end
  end
end
