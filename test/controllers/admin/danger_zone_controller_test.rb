# frozen_string_literal: true

require "test_helper"

module Admin
  class DangerZoneControllerTest < ActionDispatch::IntegrationTest
    context "The danger zone controller" do
      setup do
        @admin = create(:admin_user)
      end

      teardown do
        DangerZone.min_upload_level = User::Levels::MEMBER
        DangerZone.hide_pending_posts_for = 0
      end

      context "index action" do
        should "render" do
          get_auth admin_danger_zone_index_path, @admin
          assert_response :success
        end

        should "restrict access" do
          assert_access(User::Levels::ADMIN) { |user| get_auth admin_danger_zone_index_path, user }
        end
      end

      context "uploading limits action" do
        should "work" do
          put_auth uploading_limits_admin_danger_zone_index_path, @admin, params: { uploading_limits: { min_level: User::Levels::TRUSTED } }
          assert_equal DangerZone.min_upload_level, User::Levels::TRUSTED
        end

        should "restrict access" do
          assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| put_auth uploading_limits_admin_danger_zone_index_path, user, params: { uploading_limits: { min_level: User::Levels::TRUSTED } } }
        end
      end

      context "hide pending posts action" do
        should "work" do
          put_auth hide_pending_posts_admin_danger_zone_index_path, @admin, params: { hide_pending_posts: { duration: 24 } }
          assert_equal DangerZone.hide_pending_posts_for, 24
        end

        should "restrict access" do
          assert_access(User::Levels::ADMIN, success_response: :redirect) { |user| put_auth hide_pending_posts_admin_danger_zone_index_path, user, params: { hide_pending_posts: { duration: 24 } } }
        end
      end
    end
  end
end
