# frozen_string_literal: true

module RuboCop
  module Cop
    module Local
      class CurrentUserOutsideOfRequests < Base
        MSG = "CurrentUser should only be used within the request cycle (controllers, views, helpers, decorators)"

        def_node_matcher(:current_user?, <<~PATTERN)
          (const _ :CurrentUser)
        PATTERN

        def on_send(node)
          return unless starts_with_current_user?(node)
          return if ignored_method?(node)
          add_offense(node, message: MSG)
        end

        def on_const(node)
          return unless current_user?(node)
          return if ignored_method?(node)
          return if node.parent&.send_type? && node.parent.receiver == node
          add_offense(node, message: MSG)
        end

        private

        def starts_with_current_user?(node)
          node.receiver && current_user?(node.receiver)
        end

        def ignored_method?(node)
          enclosing_method = node.each_ancestor(:def, :defs).first

          return false unless enclosing_method && (enclosing_method.def_type? || enclosing_method.defs_type?)

          method_name = enclosing_method.method_name.to_s
          ignored.any? { |pattern| pattern.match?(method_name) }
        end

        def ignored
          @ignored ||= begin
            pattern = ignored_patterns
            prefix = ignored_prefixes.map { |p| Regexp.new("^#{p}") }
            suffix = ignored_suffixes.map { |p| Regexp.new("#{p}$") }
            methods = ignored_methods.map { |p| Regexp.new("^#{p}$") }
            [*pattern, *prefix, *suffix, *methods]
          end
        end

        def ignored_patterns
          @ignored_patterns ||= Array(cop_config["IgnoredMethodPatterns"]).map { |p| Regexp.new(p) }
        end

        def ignored_prefixes
          @ignored_prefixes ||= Array(cop_config["IgnoredMethodPrefixes"])
        end

        def ignored_suffixes
          @ignored_suffixes ||= Array(cop_config["IgnoredMethodSuffixes"])
        end

        def ignored_methods
          @ignored_methods ||= Array(cop_config["IgnoredMethods"])
        end
      end
    end
  end
end
