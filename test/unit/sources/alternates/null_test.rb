# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module Sources
  module Alternates
    class NullTest < ActiveSupport::TestCase
      extend(Helper)

      context("A source from an unknown site") do
        alternate_should_work(
          "http://oremuhax.x0.com/yoro1603.jpg",
          Sources::Alternates::Null,
          "http://oremuhax.x0.com/yoro1603.jpg",
        )
      end

      context("A source from imgur") do
        alternate_should_work(
          "http://imgur.com/gallery/qFKojyz",
          Sources::Alternates::Null,
          "https://imgur.com/gallery/qFKojyz",
        )
      end
    end
  end
end
