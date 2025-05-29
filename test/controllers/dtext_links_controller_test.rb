# frozen_string_literal: true

require("test_helper")

class DtextLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    as(@user) do
      @wiki = create(:wiki_page, title: "case", body: "[[test]]")
      @forum = create(:forum_post, topic: build(:forum_topic, title: "blah"), body: "[[case]]")
      @pool = create(:pool, description: "[[case]]")
      create(:tag, name: "test")
    end
  end

  context("index action") do
    should("render") do
      get(dtext_links_path)
      assert_response(:success)
    end
  end
end
