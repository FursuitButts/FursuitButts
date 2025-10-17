# frozen_string_literal: true

require("test_helper")
require_relative("helper")

module Sources
  module Alternates
    class E621Test < ActiveSupport::TestCase
      extend(Helper)

      context("A source from E621") do
        alternate_should_work(
          "https://e621.net/posts/3242510",
          Sources::Alternates::E621,
          "https://e621.net/posts/3242510",
        )
      end

      context("A source from E926") do
        alternate_should_work(
          "https://e926.net/posts/3242510",
          Sources::Alternates::E621,
          "https://e621.net/posts/3242510",
        )
      end

      context("A direct link from E621") do
        setup do
          stub_request(:get, "https://e621.net/posts.json?md5=b919c42410b3e90a3dd2667612ccebc2").to_return(status: 200, body: %({"post":{"id":3242510}}), headers: {})
        end

        alternate_should_work(
          "https://static1.e621.net/data/b9/19/b919c42410b3e90a3dd2667612ccebc2.png",
          Sources::Alternates::E621,
          "https://static1.e621.net/data/b9/19/b919c42410b3e90a3dd2667612ccebc2.png",
        )
      end

      context("A direct link from E926") do
        setup do
          stub_request(:get, "https://e621.net/posts.json?md5=b919c42410b3e90a3dd2667612ccebc2").to_return(status: 200, body: %({"post":{"id":3242510}}), headers: {})
        end

        alternate_should_work(
          "https://static1.e926.net/data/b9/19/b919c42410b3e90a3dd2667612ccebc2.png",
          Sources::Alternates::E621,
          "https://static1.e621.net/data/b9/19/b919c42410b3e90a3dd2667612ccebc2.png",
        )
      end
    end
  end
end
