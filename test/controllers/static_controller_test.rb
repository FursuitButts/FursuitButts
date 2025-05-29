# frozen_string_literal: true

require("test_helper")

class StaticControllerTest < ActionDispatch::IntegrationTest
  context("The static controller") do
    context("the robots action") do
      should("render") do
        get(robots_path)
      end
    end
  end
end
