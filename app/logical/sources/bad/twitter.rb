# frozen_string_literal: true

module Sources
  module Bad
    class Twitter < Base
      attr_reader(:has_profile, :has_submission, :has_direct)

      DOMAINS = %w[twimg.com x.com].freeze
      PROFILE_REGEX = %r{x\.com/(\w{1,15})$}
      INTENT_USER_REGEX = %r{x\.com/intent/user}
      SUBMISSION_REGEX = %r{x\.com/(\w{1,15})/status/(\d+)}
      DIRECT_REGEX = %r{(?:pbs|video)\.twimg\.com/}
      INTENT_REGEX = %r{x\.com/i/(?:web/)?status/(\d+)$}

      def bad?
        sources.each do |source|
          case Addressable::URI.heuristic_parse(source)
          when PROFILE_REGEX, INTENT_USER_REGEX
            @has_profile = true
          when SUBMISSION_REGEX, INTENT_REGEX
            @has_submission = true
          when DIRECT_REGEX
            @has_direct = true
          end
        end

        (has_profile || has_direct) && !has_submission
      end

      def self.match?(url)
        DOMAINS.include?(url.domain)
      end
    end
  end
end
