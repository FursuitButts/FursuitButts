# frozen_string_literal: true

require("test_helper")

class DtextLinksControllerTest < ActionDispatch::IntegrationTest
  context("The DText links controller") do
    setup do
      create(:wiki_page, title: "case", body: "[[test]]")
      create(:forum_post, body: "[[case]]")
      create(:pool, description: "[[case]]")
      create(:tag, name: "test")
    end

    context("index action") do
      should("render") do
        get(dtext_links_path)
        assert_response(:success)
      end
    end
  end
end
