# frozen_string_literal: true

module RuboCop
  module Cop
    module Local
      class BelongsToUserInvalidIp < Base
        extend(AutoCorrector)
        include(ActiveRecordHelper)
        include(NodeFormattingHelper)
        MSG = "`ip: %<ip_set>s` set for `belongs_to_user(%<attr>s)` when `%<ip_attr>s` column does not exist"

        def_node_matcher(:belongs_to_user?, <<~PATTERN)
          (send nil? :belongs_to_user $_ $...)
        PATTERN

        def on_send(node)
          belongs_to_user?(node) do |receiver, code|
            return unless receiver.str_type? || receiver.sym_type?
            attr = format_node(receiver)
            return if attr.blank?

            options = format_node(code.last, {})
            return if options[:ip].blank? || options[:ip] == false

            return unless schema

            table = table(node)
            return unless table

            column = options[:ip] == true ? "#{attr}_ip_addr" : options[:ip].to_s
            exists = table.with_column?(name: column)

            return if exists

            register_offense(node, attr, options, column, options[:ip])
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

        def register_offense(node, attr, options, column, original)
          message = format(MSG, attr: attr.inspect, ip_attr: "#{table(node).name}.#{column}".inspect, ip_set: original.inspect)

          add_offense(node, message: message) do |corrector|
            new_options = format_new_options(attr, options)

            corrector.replace(node.source_range, "belongs_to_user(#{new_options})")
          end
        end

        def format_new_options(attr, options)
          list = [attr.inspect]

          options.delete(:ip)
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
