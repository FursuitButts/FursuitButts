# frozen_string_literal: true

module RuboCop
  module Cop
    module NodeFormattingHelper
      # rubocop:disable Lint/BooleanSymbol -- No, no I do not want literal values for the keys
      BASIC = {
        true:  true,
        false: false,
        nil:   nil,
      }.freeze
      # rubocop:enable Lint/BooleanSymbol

      def format_node(node, default = nil)
        return default if node.nil?
        return node.map { |n| format_node(n) } if node.is_a?(Array)

        case node.type
        when :sym, :str, :dstr, :int, :dsym, :float, :rational
          format_literal(node)
        when *BASIC.keys
          get_basic(node)
        when :pair
          format_pair(node)
        when :hash
          format_hash(node)
        when :lvar, :block
          node.source
        when :array
          format_array(node)
        else
          raise(StandardError, "Don't know how to format #{node.type}")
        end
      end

      private

      def format_literal(node)
        node.value
      end

      def get_basic(node)
        BASIC[node.type]
      end

      def format_pair(node)
        [format_node(node.key), format_node(node.value)]
      end

      def format_hash(node)
        node.pairs.to_h { |pair| format_node(pair) }
      end

      def format_array(node)
        node.children.map { |n| format_node(n) }
      end
    end
  end
end
