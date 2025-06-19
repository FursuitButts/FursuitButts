# frozen_string_literal: true

module BulkUpdateRequestCommands
  class EmptyLine < Base
    set_command(:empty_line)
    set_arguments
    set_regex(/\A\s*\z/i, [])
    set_untokenize { "" }
    set_to_dtext { "" }

    def process(_processor, _approver)
      ensure_valid!
    end
  end
end
