# frozen_string_literal: true

module BulkUpdateRequestCommands
  class Invalid < Base
    set_command(:invalid)
    set_arguments(:text, :comment)
    set_regex(nil, %i[pass comment])
    set_untokenize { |text, comment| "#{text}#{" # #{comment}" if comment}" }
    set_to_dtext { |text, comment| "#{text}#{" # #{comment}" if comment}" }

    validate(:add_error)

    def add_error
      errors.add(:base, "is invalid")
    end

    def process(_processor, _approver)
      raise(ProcessingError, "Error: Cannot approve invalid commands")
    end

    def self.tokenize(line)
      token = line.split("#").map(&:strip)
      token.fill(nil, token.length...2)
    end
  end
end
