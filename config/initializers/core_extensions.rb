# frozen_string_literal: true

module FemboyFans
  module Extensions
    module String
      def to_escaped_for_sql_like
        gsub(/%|_|\*|\\\*|\\\\|\\/) do |str|
          case str
          when "%"    then '\%'
          when "_"    then '\_'
          when "*"    then "%"
          when '\*'   then "*"
          when "\\\\", "\\" then "\\\\"
          end
        end
      end

      def truthy?
        match?(/\A(true|t|yes|y|on|1)\z/i)
      end

      def falsy?
        match?(/\A(false|f|no|n|off|0)\z/i)
      end

      # @return [Boolean] True if the string contains only balanced parentheses; false if the string contains unbalanced parentheses.
      def has_balanced_parens?(open = "(", close = ")")
        parens = 0

        chars.each do |char|
          if char == open
            parens += 1
          elsif char == close
            parens -= 1
            return false if parens < 0
          end
        end

        parens == 0
      end
    end
  end
end

class String
  include FemboyFans::Extensions::String
end
