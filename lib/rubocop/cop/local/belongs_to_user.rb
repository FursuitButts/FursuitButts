# frozen_string_literal: true

module RuboCop
  module Cop
    module Local
      class BelongsToUser < Base
        extend(AutoCorrector)
        include(NodeFormattingHelper)
        MSG = "Use `belongs_to_user(%<attr>s)` instead of `belongs_to(%<attr>s)`"

        def_node_matcher(:belongs_to_user?, <<~PATTERN)
          (send nil? :belongs_to $_ $...)
        PATTERN

        def on_send(node)
          belongs_to_user?(node) do |receiver, code|
            return unless receiver.str_type? || receiver.sym_type?
            attr = format_node(receiver)

            return if attr.blank? || !code.last&.hash_type?
            options = format_node(code.last, {})

            # Match belongs_to(:user)
            if attr.to_sym == :user && !options.key?(:class_name)
              register_offense(node, attr, options)
              return
            end

            # Match belongs_to(attr, class_name: "User")
            if options[:class_name] == "User"
              register_offense(node, attr, options)
            end
          end
        end

        private

        def register_offense(node, attr, options)
          message = format(MSG, attr: attr.inspect)

          add_offense(node, message: message) do |corrector|
            new_options = format_new_options(attr, options)

            corrector.replace(node.source_range, "belongs_to_user(#{new_options})")
          end
        end

        def format_new_options(attr, options)
          list = [attr.inspect]

          options.delete(:class_name)
          if options.any?
            options.each do |k, v|
              list << "#{k}: #{v.inspect}"
            end
          end
          list.join(", ")
        end
      end
    end
  end
end
