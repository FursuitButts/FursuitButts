# frozen_string_literal: true

require("test_helper")

class WikiPageTest < ActiveSupport::TestCase
  context("A wiki page") do
    context("that is protected") do
      should("not be editable by a member") do
        CurrentUser.user = create(:moderator_user)
        @wiki_page = create(:wiki_page, protection_level: User::Levels::JANITOR)
        CurrentUser.user = create(:user)
        @wiki_page.update(body: "hello")
        assert_equal(["Is protected and cannot be updated"], @wiki_page.errors.full_messages)
      end

      should("be editable by a moderator") do
        CurrentUser.user = create(:moderator_user)
        @wiki_page = create(:wiki_page, protection_level: User::Levels::JANITOR)
        CurrentUser.user = create(:moderator_user)
        @wiki_page.update(body: "hello")
        assert_equal([], @wiki_page.errors.full_messages)
      end
    end

    context("updated by a moderator") do
      setup do
        @user = create(:moderator_user)
        CurrentUser.user = @user
        @wiki_page = create(:wiki_page)
      end

      should("allow the protection_level attribute to be updated") do
        @wiki_page.update(protection_level: User::Levels::JANITOR)
        @wiki_page.reload
        assert_equal(User::Levels::JANITOR, @wiki_page.protection_level)
      end
    end

    context("updated by a regular user") do
      setup do
        @user = create(:user)
        CurrentUser.user = @user
        @wiki_page = create(:wiki_page, title: "HOT POTATO")
      end

      should("normalize its title") do
        assert_equal("hot_potato", @wiki_page.title)
      end

      should("search by title") do
        assert_equal("hot_potato", WikiPage.titled("hot potato").title)
        assert_nil(WikiPage.titled(nil))
      end

      should("create versions") do
        assert_difference("WikiPageVersion.count") do
          @wiki_page = create(:wiki_page, title: "xxx")
        end

        assert_difference("WikiPageVersion.count") do
          @wiki_page.update(title: "yyy")
        end
      end

      should("revert to a prior version") do
        @wiki_page.update(title: "yyy")
        version = WikiPageVersion.first
        @wiki_page.revert_to!(version)
        @wiki_page.reload
        assert_equal("hot_potato", @wiki_page.title)
      end

      should("differentiate between updater and creator") do
        another_user = create(:user)
        as(another_user) do
          @wiki_page.title = "yyy"
          @wiki_page.save
        end
        version = WikiPageVersion.last
        assert_not_equal(@wiki_page.creator_id, version.updater_id)
      end

      should("update its dtext links") do
        @wiki_page.update!(body: "[[long hair]]")
        assert_equal(1, @wiki_page.dtext_links.size)
        assert_equal("wiki_link", @wiki_page.dtext_links.first.link_type)
        assert_equal("long_hair", @wiki_page.dtext_links.first.link_target)

        @wiki_page.update!(body: "https://www.google.com")
        assert_equal(1, @wiki_page.dtext_links.size)
        assert_equal("external_link", @wiki_page.dtext_links.first.link_type)
        assert_equal("https://www.google.com", @wiki_page.dtext_links.first.link_target)

        @wiki_page.update!(body: "nothing")
        assert_equal(0, @wiki_page.dtext_links.size)
      end
    end

    context("for a help page") do
      setup do
        @janitor = create(:janitor_user)
        @admin = create(:admin_user)
        as(@admin) do
          @help = create(:help_page)
          @wiki = @help.wiki_page
        end
      end

      should("not allow the title to be changed by janitors") do
        as(@janitor) do
          @title = @wiki.title
          @wiki.update(title: "new_title")
          assert_equal(["Title is used as a help page and cannot be changed"], @wiki.errors.full_messages)
          assert_equal(@title, @wiki.reload.title)
          assert_equal(@title, @help.reload.wiki_page_title)
        end
      end

      should("allow the title to be changed by admins") do
        as(@admin) do
          @wiki.update(title: "new_title")
          assert_equal([], @wiki.errors.full_messages)
          assert_equal("new_title", @wiki.reload.title)
          assert_equal("new_title", @help.reload.wiki_page_title)
        end
      end

      should("not allow deleting the wiki page") do
        as(@admin) do
          @wiki.destroy
          assert_equal(["Wiki page is used by a help page"], @wiki.errors.full_messages)
          assert_not_nil(WikiPage.find_by(id: @wiki.id))
        end
      end
    end
  end
end
