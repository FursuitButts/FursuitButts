# frozen_string_literal: true

module Sources
  module Alternates
    class Base
      attr_reader(:url, :gallery_url, :submission_url, :direct_url, :additional_urls, :parsed_url)

      SECURE_DOMAINS = %w[weasyl.com e-hentai.org hentai-foundry.com paheal.net imgur.com].freeze

      def initialize(url)
        @url = url

        @parsed_url = begin
          Addressable::URI.heuristic_parse(url)
        rescue StandardError
          nil
        end

        if @parsed_url.present?
          begin
            if force_https?
              @parsed_url.scheme = "https"
              @url = @parsed_url.to_s
            end

            parse
          rescue StandardError
            @parsed_url = nil
          end
        end
      end

      def force_https?
        return false if @parsed_url.blank?
        SECURE_DOMAINS.include?(@parsed_url.domain)
      end

      def match?
        return false if parsed_url.nil?
        parsed_url.domain.in?(domains)
      end

      def domains
        []
      end

      def parse
      end

      def remove_duplicates(sources)
        sources
      end

      def original_url
        @url
      end
    end
  end
end
