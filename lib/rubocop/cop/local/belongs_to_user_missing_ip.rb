# frozen_string_literal: true

module RuboCop
  module Cop
    module Local
      class BelongsToUserMissingIp < Base
        extend(AutoCorrector)
        include(ActiveRecordHelper)
        include(NodeFormattingHelper)
        MSG = "Specify `ip: true` when a `belongs_to_user(%<attr>s)` relation has a corresponding `%<ip_attr>s` column"

        def_node_matcher(:belongs_to_user?, <<~PATTERN)
          (send nil? :belongs_to_user $_ $...)
        PATTERN

        def on_send(node)
          belongs_to_user?(node) do |receiver, code|
            return unless receiver.str_type? || receiver.sym_type?
            attr = format_node(receiver)
            return if attr.blank?

            options = format_node(code.last, {})
            return if options[:ip].present? && options[:ip] != false

            return unless schema

            table = table(node)
            return unless table

            column = "#{attr}_ip_addr"
            exists = table.with_column?(name: column)

            return unless exists

            register_offense(node, attr, options, column)
          end
        end

        private

        def class_node(node)
          node.each_ancestor.find(&:class_type?)
        end

        def table(node)
          klass = class_node(node)
          return unless klass

          schema.table_by(name: table_name(klass))
        end

        def register_offense(node, attr, options, column)
          message = format(MSG, attr: attr.inspect, ip_attr: column.inspect)

          add_offense(node, message: message) do |corrector|
            new_options = format_new_options(attr, options)

            corrector.replace(node.source_range, "belongs_to_user(#{new_options})")
          end
        end

        def format_new_options(attr, options)
          list = [attr.inspect, "ip: true"]

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
