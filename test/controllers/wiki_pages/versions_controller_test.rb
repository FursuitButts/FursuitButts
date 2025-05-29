# frozen_string_literal: true

require("test_helper")

module WikiPages
  class VersionsControllerTest < ActionDispatch::IntegrationTest
    context("The wiki page versions controller") do
      setup do
        @user = create(:user)
        as(@user) do
          @wiki_page = create(:wiki_page)
          @wiki_page.update(body: "1 2")
          @wiki_page.update(body: "2 3")
        end
      end

      context("index action") do
        should("list all versions") do
          get(wiki_page_versions_path)
          assert_response(:success)
        end

        should("list all versions that match the search criteria") do
          get(wiki_page_versions_path, params: { search: { wiki_page_id: @wiki_page.id } })
          assert_response(:success)
        end

        should("restrict access") do
          assert_access(User::Levels::ANONYMOUS) { |user| get_auth(wiki_page_versions_path, user) }
        end
      end

      context("show action") do
        should("render") do
          get(wiki_page_version_path(@wiki_page.versions.first))
          assert_response(:success)
        end

        should("restrict access") do
          assert_access(User::Levels::ANONYMOUS) { |user| get_auth(wiki_page_version_path(@wiki_page.versions.first), user) }
        end
      end

      context("diff action") do
        should("render") do
          get(diff_wiki_page_versions_path, params: { thispage: @wiki_page.versions.first.id, otherpage: @wiki_page.versions.last.id })
          assert_response(:success)
        end

        should("restrict access") do
          assert_access(User::Levels::ANONYMOUS) { |user| get_auth(diff_wiki_page_versions_path, user, params: { thispage: @wiki_page.versions.first.id, otherpage: @wiki_page.versions.last.id }) }
        end
      end
    end
  end
end
