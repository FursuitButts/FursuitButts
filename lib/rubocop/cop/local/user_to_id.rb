# frozen_string_literal: true

module RuboCop
  module Cop
    module Local
      class UserToId < Base
        extend(AutoCorrector)
        include(NodeFormattingHelper)
        MSG = "Use `u2id(%<var>s)` instead of `%<original>s`"

        def on_if(node)
          return unless node.ternary?

          condition, if_branch, else_branch = *node
          return unless user_check?(condition)
          return unless id_call?(if_branch)
          return unless same_value?(if_branch.receiver, else_branch)

          message = format(MSG, var: else_branch.source, original: node.source)
          add_offense(node, message: message) do |corrector|
            corrector.replace(node.source_range, "u2id(#{else_branch.source})")
          end
        end

        private

        def user_check?(node)
          node&.send_type? &&
            node.method?(:is_a?) &&
            node.arguments.first&.const_name == "User"
        end

        def id_call?(node)
          node&.send_type? && node.method?(:id)
        end

        def same_value?(a, b) # rubocop:disable Naming/MethodParameterName
          a && b && a.source == b.source
        end
      end
    end
  end
end
