# frozen_string_literal: true

module Sources
  module Bad
    class Telegram < Base
      attr_reader(:has_invite, :has_channel, :has_channel_message, :has_message)

      DOMAINS = %w[t.me telegram.me telegram.dog].freeze
      INVITE_REGEX = %r{(?:t|telegram)\.(?:me|dog)/(joinchat/|\+)?([\w-]+)$}
      CHANNEL_REGEX = %r{(?:t|telegram)\.(?:me|dog)/c/(\d+)$}
      # only works if you are in the channel, not useful on its own
      CHANNEL_MESSAGE_REGEX = %r{(?:t|telegram)\.(?:me|dog)/c/(\d+)/(\d+)$}
      MESSAGE_REGEX = %r{(?:t|telegram)\.(?:me|dog)/(?!c/)([\w-]+)/(\d+)$}

      def bad?
        sources.each do |source|
          case Addressable::URI.heuristic_parse(source)
          when INVITE_REGEX
            @has_invite = true
          when CHANNEL_REGEX
            @has_channel = true
          when CHANNEL_MESSAGE_REGEX
            @has_channel_message = true
          when MESSAGE_REGEX
            @has_message = true
          end
        end

        return true if has_channel && !has_message && !has_channel_message && !has_invite
        return !(has_invite || has_message) if has_channel_message
        has_invite && !has_message
      end

      def self.match?(url)
        DOMAINS.include?(url.domain)
      end
    end
  end
end
