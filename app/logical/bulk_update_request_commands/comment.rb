# frozen_string_literal: true

module BulkUpdateRequestCommands
  class Comment < Base
    set_command(:comment)
    set_arguments(:comment)
    set_regex(/\A# ?(.+)\z/i, [:pass])
    set_untokenize { |comment| "# #{comment}" }
    set_to_dtext { |comment| "# #{comment}" }

    def process(_processor, _approver)
      ensure_valid!
    end
  end
end
