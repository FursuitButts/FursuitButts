# frozen_string_literal: true

module Sources
  module Bad
    class Furaffinity < Base
      attr_reader(:has_profile, :has_gallery, :has_submission, :has_direct)

      DOMAINS = %w[furaffinity.net facdn.net].freeze
      PROFILE_REGEX = %r{furaffinity\.net/user/([\w.~\-\[\]]+)}
      GALLERY_REGEX = %r{furaffinity\.net/gallery/([\w.~\-\[\]]+)}
      SUBMISSION_REGEX = %r{furaffinity\.net/(?:view|full)/(\d+)}
      DIRECT_REGEX = %r{d2?\.(?:facdn|furaffinity)\.net/art/([\w.~\-\[\]]+)}

      def bad?
        sources.each do |source|
          case Addressable::URI.heuristic_parse(source)
          when PROFILE_REGEX
            @has_profile = true
          when GALLERY_REGEX
            @has_gallery = true
          when SUBMISSION_REGEX
            @has_submission = true
          when DIRECT_REGEX
            @has_direct = true
          end
        end

        (has_profile || has_gallery || has_direct) && !has_submission
      end

      def self.match?(url)
        DOMAINS.include?(url.domain)
      end
    end
  end
end
