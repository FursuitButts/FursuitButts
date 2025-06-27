# frozen_string_literal: true

module RuboCop
  module Cop
    module Local
      class ResolvableUser < Base
        extend(AutoCorrector)
        include(ActiveRecordHelper)
        include(NodeFormattingHelper)
        MSG = "use `belongs_to_user(%<attr>s)` when `%<id_column>s` column exists"
        MSG_IP = "use `belongs_to_user(%<attr>s, ip: true)` when `%<id_column>s` and `%<ip_column>s` columns exist"

        def_node_matcher(:resolvable?, <<~PATTERN)
          (send nil? :resolvable $_ $...)
        PATTERN

        def on_send(node)
          resolvable?(node) do |receiver, code|
            return unless receiver.str_type? || receiver.sym_type?
            attr = format_node(receiver)
            return if attr.blank?

            options = format_node(code.last, {})

            return unless schema

            table = table(node)
            return unless table

            column = "#{attr}_id"
            ip_column = "#{attr}_ip_addr"
            exists = table.with_column?(name: column)
            ip_exists = table.with_column?(name: ip_column)

            return unless exists
            options[:ip] = true if ip_exists

            register_offense(node, attr, options, column, ip_column)
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

        def register_offense(node, attr, options, id_column, ip_column)
          if options[:ip]
            message = format(MSG_IP, attr: attr.inspect, id_column: id_column.inspect, ip_column: ip_column.inspect)
          else
            message = format(MSG, attr: attr.inspect, id_column: id_column.inspect)
          end

          add_offense(node, message: message) do |corrector|
            new_options = format_new_options(attr, options)

            corrector.replace(node.source_range, "belongs_to_user(#{new_options})")
          end
        end

        def format_new_options(attr, options)
          list = [attr.inspect]

          if options.any?
            options.slice(:ip, :clone).merge(options.except(:ip, :clone)).each do |k, v|
              list << "#{k}: #{v.inspect}"
            end
          end
          list.join(", ")
        end
      end
    end
  end
end
