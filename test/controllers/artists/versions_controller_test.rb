# frozen_string_literal: true

require("test_helper")

module Artists
  class VersionsControllerTest < ActionDispatch::IntegrationTest
    context("An artist versions controller") do
      setup do
        @user = create(:trusted_user)
        as(@user) do
          @artist = create(:artist)
        end
      end

      should("get the index page") do
        get_auth(artist_versions_path, @user)
        assert_response(:success)
      end

      should("get the index page when searching for something") do
        get_auth(artist_versions_path(search: { artist_name: @artist.name }), @user)
        assert_response(:success)
      end

      should("restrict access") do
        assert_access(User::Levels::ANONYMOUS) { |user| get_auth(artist_versions_path, user) }
      end
    end
  end
end
