# frozen_string_literal: true

module Sources
  module Alternates
    class Furaffinity < Base
      IMAGE_TO_ARTIST = %r{d2?\.(?:facdn|furaffinity)\.net/art/([0-9a-zA-Z_.~\-\[\]]+)}
      SUBMISSION_URL = %r{furaffinity\.net/view/(\d+)}

      def force_https?
        true
      end

      def domains
        %w[furaffinity.net facdn.net]
      end

      def parse
        # Add gallery link, parsed from direct link
        if @url =~ IMAGE_TO_ARTIST
          @gallery_url = "https://furaffinity.net/user/#{$1}"
        end
      end

      def original_url
        # Handle old CDN or old broken CDN
        @parsed_url.host = "d.furaffinity.net" if %w[d.facdn.net d2.facdn.net].include?(@parsed_url.host)
        # Convert /full/ submission links to /view/ links
        @parsed_url.path = "/view/#{@parsed_url.path[6..]}" if @parsed_url.path.start_with?("/full/")
        # Remove "?upload-successful" query after upload
        @parsed_url.query = nil if @parsed_url.query == "upload-successful"
        # Remove comment anchor
        @parsed_url.fragment = nil if @parsed_url.fragment&.start_with?("cid:")
        @parsed_url.host = @parsed_url.host[4..] if @parsed_url.host.start_with?("www.")
        @parsed_url.path = @parsed_url.path.delete_suffix("/") if @parsed_url.path.end_with?("/")

        @url = @parsed_url.to_s
      end
    end
  end
end
