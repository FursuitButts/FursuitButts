# frozen_string_literal: true

require "test_helper"

module MediaAssets
  class MascotsControllerTest < ActionDispatch::IntegrationTest
    context "The mascot media assets controller" do
      setup do
        @user = create(:user, created_at: 2.weeks.ago)
        @user2 = create(:user)
        @janitor = create(:janitor_user)
        @media_asset = create(:jpg_mascot_media_asset, creator: @user)
      end

      context "index action" do
        should "render" do
          get_auth mascot_media_assets_path, @user
          assert_response :success
        end

        should "list created media assets" do
          get_auth mascot_media_assets_path, @user
          assert_response :success
          assert_select "#mascot-media-asset-#{@media_asset.id}", count: 1
        end

        should "list all media assets for staff" do
          get_auth mascot_media_assets_path, @janitor
          assert_response :success
          assert_select "#mascot-media-asset-#{@media_asset.id}", count: 1
        end

        should "not list media assets created by others" do
          get_auth mascot_media_assets_path, @user2
          assert_response :success
          assert_select "#mascot-media-asset-#{@media_asset.id}", count: 0
        end

        should "restrict access" do
          assert_access(User::Levels::MEMBER) { |user| get_auth mascot_media_assets_path, user }
        end
      end
    end
  end
end
