# frozen_string_literal: true

module Sources
  module Bad
    class E621 < Base
      attr_reader(:has_post, :has_md5)

      DOMAINS = %w[e621.net e926.net].freeze
      POST_REGEX = %r{(?:e621|e926)\.net/posts/\d+}
      MD5_REGEX = %r{static\d\.(?:e621|e926)\.net/data/[a-z\d]{2}/[a-z\d]{2}/[a-z\d]{32}}

      def bad?
        sources.each do |source|
          case Addressable::URI.heuristic_parse(source)
          when POST_REGEX
            @has_post = true
          when MD5_REGEX
            @has_md5 = true
          end
        end

        # bad if we have md5 without post, and bad if we have anything else and neither md5 nor post (such as an artist link)
        (has_md5 && !has_post) || (!has_md5 && !has_post)
      end

      def self.match?(url)
        DOMAINS.include?(url.domain)
      end
    end
  end
end
