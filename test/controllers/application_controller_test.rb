# frozen_string_literal: true

require("test_helper")

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  context("The application controller") do
    should("return 406 Not Acceptable for a bad file extension") do
      get(posts_path, params: { format: :jpg })
      assert_response(406)

      get(posts_path, params: { format: :blah })
      assert_response(406)

      get(post_path("bad.json"))
      assert_response(404)

      get(post_path("bad.jpg"))
      assert_response(406)

      get(post_path("bad.blah"))
      assert_response(406)
    end

    context("on a PaginationError") do
      should("return 410 Gone even with a bad file extension") do
        get(posts_path, params: { page: 999_999_999 }, as: :json)
        assert_response(410)

        get(posts_path, params: { page: 999_999_999 }, as: :jpg)
        assert_response(410)

        get(posts_path, params: { page: 999_999_999 }, as: :blah)
        assert_response(410)
      end
    end

    context("on api authentication") do
      setup do
        @user = create(:user, password: "password")
        @api_key = create(:api_key, user: @user)

        ActionController::Base.allow_forgery_protection = true
      end

      teardown do
        ActionController::Base.allow_forgery_protection = false
      end

      context("using http basic auth") do
        should("succeed for api key matches") do
          basic_auth_string = "Basic #{::Base64.encode64("#{@user.name}:#{@api_key.key}")}"
          get(edit_users_path, headers: { HTTP_AUTHORIZATION: basic_auth_string })
          assert_response(:success)
        end

        should("fail for api key mismatches") do
          basic_auth_string = "Basic #{::Base64.encode64("#{@user.name}:badpassword")}"
          get(edit_users_path, headers: { HTTP_AUTHORIZATION: basic_auth_string })
          assert_response(401)
        end

        should("succeed for non-GET requests without a CSRF token") do
          assert_changes(-> { @user.reload.enable_safe_mode }, from: false, to: true) do
            basic_auth_string = "Basic #{::Base64.encode64("#{@user.name}:#{@api_key.key}")}"
            post(update_users_path, headers: { HTTP_AUTHORIZATION: basic_auth_string }, params: { user: { enable_safe_mode: "true" } }, as: :json)
            assert_response(:success)
          end
        end
      end

      context("using the api_key parameter") do
        should("succeed for api key matches") do
          get(edit_users_path, params: { login: @user.name, api_key: @api_key.key })
          assert_response(:success)
        end

        should("fail for api key mismatches") do
          get(edit_users_path, params: { login: @user.name })
          assert_response(401)

          get(edit_users_path, params: { api_key: @api_key.key })
          assert_response(401)

          get(edit_users_path, params: { login: @user.name, api_key: "bad" })
          assert_response(401)
        end

        should("succeed for non-GET requests without a CSRF token") do
          assert_changes(-> { @user.reload.enable_safe_mode }, from: false, to: true) do
            post(update_users_path, params: { login: @user.name, api_key: @api_key.key, user: { enable_safe_mode: "true" } }, as: :json)
            assert_response(:success)
          end
        end
      end

      context("without any authentication") do
        should("redirect to the login page") do
          get(edit_users_path)
          assert_redirected_to(new_session_path(url: edit_users_path))
        end
      end

      context("with cookie-based authentication") do
        should("not allow non-GET requests without a CSRF token") do
          # get the csrf token from the login page so we can login
          get(new_session_path)
          assert_response(:success)
          token = css_select("form input[name=authenticity_token]").first["value"]

          # login
          post(session_path, params: { authenticity_token: token, session: { name: @user.name, password: "password" } })
          assert_redirected_to(posts_path)

          # try to submit a form with cookies but without the csrf token
          post(update_users_path, headers: { HTTP_COOKIE: headers["Set-Cookie"] }, params: { user: { enable_safe_mode: "true" } })
          assert_response(403)
          assert_match(/ActionController::InvalidAuthenticityToken/, css_select("p").first.content)
          assert_equal(false, @user.reload.enable_safe_mode)
        end
      end
    end

    context("on session cookie authentication") do
      should("succeed") do
        user = create(:user, password: "password")

        post(session_path, params: { session: { name: user.name, password: "password" } })
        get(edit_users_path)

        assert_response(:success)
      end
    end

    context("when the api limit is exceeded") do
      should("fail with a 429 error") do
        user = create(:user)
        post = create(:post, rating: "s", uploader: user)
        UserThrottle.any_instance.stubs(:throttled?).returns(true)

        put_auth(post_path(post), user, params: { post: { rating: "e" } })

        assert_response(429)
        assert_equal("s", post.reload.rating)
      end
    end

    context("when the user has an invalid username") do
      setup do
        @user = build(:user, name: "12345")
        @user.save(validate: false)
      end

      should("redirect for html requests") do
        get_auth(posts_path, @user, params: { format: :html })
        assert_redirected_to(new_user_name_change_request_path)
      end

      should("not redirect for json requests") do
        get_auth(posts_path, @user, params: { format: :json })
        assert_response(:success)
      end
    end

    context("when the user is banned") do
      setup do
        @user = create(:user)
        @user2 = create(:user)
        as(create(:admin_user)) do
          @user.bans.create!(duration: -1, reason: "Test")
          @user2.bans.create!(duration: 3, reason: "Test")
        end
      end

      context("permanently") do
        should("return a 403 for html") do
          get_auth(posts_path, @user)
          assert_response(403)
        end

        should("return a 403 and the ban for json") do
          get_auth(posts_path, @user, params: { format: :json })
          assert_response(403)
          assert_equal("Account is permanently banned", @response.parsed_body["message"])
          assert_equal(@user.recent_ban.as_json, @response.parsed_body["ban"])
        end

        should("not allow acknowledging the ban") do
          get(acknowledge_bans_path(user_id: @user.signed_id(purpose: :acknowledge_ban), commit: "Acknowledge"))
          assert_response(403)
          assert_equal(true, @user.reload.is_banned?)
        end
      end

      context("temporarily") do
        should("return a 403 for html") do
          get_auth(posts_path, @user2)
          assert_response(403)
        end

        should("return a 403 and the ban for json") do
          get_auth(posts_path, @user2, params: { format: :json })
          assert_response(403)
          assert_equal("Account is banned for 3 days", @response.parsed_body["message"])
          assert_equal(@user2.recent_ban.as_json, @response.parsed_body["ban"])
        end

        should("not allow acknowledging the ban before it expires") do
          get(acknowledge_bans_path(user_id: @user2.signed_id(purpose: :acknowledge_ban), commit: "Acknowledge"))
          assert_response(403)
          assert_equal(true, @user2.reload.is_banned?)
        end

        should("allow acknowledging the ban after it expires") do
          travel_to(4.days.from_now) do
            get(acknowledge_bans_path(user_id: @user2.signed_id(purpose: :acknowledge_ban), commit: "Acknowledge"))
            assert_redirected_to(new_session_path)
          end
          assert_equal(false, @user2.reload.is_banned?)
        end

        should("not automatically unban after the ban expires") do
          travel_to(4.days.from_now) do
            get_auth(posts_path, @user2)
            assert_redirected_to(acknowledge_bans_path(user_id: @user2.signed_id(purpose: :acknowledge_ban)))
          end
          assert_equal(true, @user2.reload.is_banned?)
        end
      end

      should("not allow acknowledging the ban if it no longer exists") do
        @user2.recent_ban.delete
        get(acknowledge_bans_path(user_id: @user2.signed_id(purpose: :acknowledge_ban), commit: "Acknowledge"))
        assert_response(403)
        assert_equal(true, @user2.reload.is_banned?)
      end
    end

    context("the only parameter") do
      setup do
        @user = create(:user)
        @mod = create(:moderator_user)
        CurrentUser.user = @user
      end

      should("work") do
        get(user_path(@user), params: { only: "id", format: :json })
        assert_response(:success)
        assert_equal({ "id" => @user.id }, @response.parsed_body)
      end

      should("work with multiple attributes") do
        get(user_path(@user), params: { only: "id,name", format: :json })
        assert_response(:success)
        assert_equal({ "id" => @user.id, "name" => @user.name }, @response.parsed_body)
      end

      should("work with nested attributes") do
        @artist = create(:artist, linked_user: @user)
        get(user_path(@user), params: { only: "artists[id]", format: :json })
        assert_response(:success)
        assert_equal({ "artists" => [{ "id" => @artist.id }] }, @response.parsed_body)
      end

      should("work with multiple nested attributes") do
        @artist = create(:artist, linked_user: @user)
        @ban = as(@mod) { create(:ban, user: @user, banner: @mod) }
        get(user_path(@user), params: { only: "artists[id,name],bans[id]", format: :json })
        assert_response(:success)
        assert_equal({ "artists" => [{ "id" => @artist.id, "name" => @artist.name }], "bans" => [{ "id" => @ban.id }] }, @response.parsed_body)
      end

      should("not reveal hidden relations") do
        as(@mod) do
          @forum = create(:forum_topic, is_hidden: true)
          @bur = create(:bulk_update_request, forum_topic: @forum)
        end
        get_auth(bulk_update_request_path(@bur), @user, params: { only: "forum_topic[id],creator[id]", format: :json })
        assert_response(:success)
        assert_equal({ "creator" => { "id" => @mod.id } }, @response.parsed_body)
      end

      should("not allow unspecified includes") do
        create(:dmail, owner: @user)
        get_auth(user_path(@user), @user, params: { only: "dmails[id]", format: :json })
        assert_response(:success)
        assert_equal({}, @response.parsed_body)
      end

      should("allow underscore") do
        get_auth(user_path(@user), @user, params: { only: "_", format: :json })
        assert_response(:success)
        assert_equal(as(@user) { @user.reload.as_json }, @response.parsed_body)
      end

      should("allow underscore and other includes") do
        @artist = create(:artist, linked_user: @user)
        get_auth(user_path(@user), @user, params: { only: "_,artists", format: :json })
        assert_response(:success)
        @user.reload
        assert_equal(as(@user) { @user.as_json.merge({ "artists" => [@artist.as_json] }) }, @response.parsed_body)
      end
    end
  end
end
