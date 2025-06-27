# frozen_string_literal: true

require("test_helper")

module Pools
  class VersionsControllerTest < ActionDispatch::IntegrationTest
    context("The pool versions controller") do
      setup do
        @user = create(:user)
      end

      context("index action") do
        setup do
          @pool = create(:pool, creator: @user)
          @user2 = create(:user)
          @user3 = create(:user)

          @pool.update_with(@user2, post_ids: "1 2")

          @pool.update_with(@user3, post_ids: "1 2 3 4")

          @versions = @pool.versions
        end

        should("list all versions") do
          get_auth(pool_versions_path, @user)
          assert_response(:success)
          assert_select("#pool-version-#{@versions[0].id}")
          assert_select("#pool-version-#{@versions[1].id}")
          assert_select("#pool-version-#{@versions[2].id}")
        end

        should("list all versions that match the search criteria") do
          get_auth(pool_versions_path, @user, params: { search: { updater_id: @user2.id } })
          assert_response(:success)
          assert_select("#pool-version-#{@versions[0].id}", false)
          assert_select("#pool-version-#{@versions[1].id}")
          assert_select("#pool-version-#{@versions[2].id}", false)
        end

        should("restrict access") do
          assert_access(User::Levels::ANONYMOUS) { |user| get_auth(pool_versions_path, user) }
        end
      end
    end
  end
end
