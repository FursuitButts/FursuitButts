# frozen_string_literal: true

require("test_helper")

module Artists
  class UrlsControllerTest < ActionDispatch::IntegrationTest
    context("The artist urls controller") do
      context("index page") do
        should("render") do
          get(artist_urls_path)
          assert_response(:success)
        end

        should("render for a complex search") do
          @user = create(:user)
          @artist = create(:artist, name: "bkub", url_string: "-http://bkub.com", creator: @user)

          get(artist_urls_path(search: {
            artist_name: "bkub",
            url_matches: "*bkub*",
            is_active:   "false",
            order:       "created_at",
          }))

          assert_response(:success)
        end

        should("restrict access") do
          assert_access(User::Levels::ANONYMOUS) { |user| get_auth(artist_urls_path, user) }
        end
      end
    end
  end
end
