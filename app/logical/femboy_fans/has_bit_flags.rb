# frozen_string_literal: true

module FemboyFans
  module HasBitFlags
    extend(ActiveSupport::Concern)

    module ClassMethods
      # NOTE: the ordering of attributes has to be fixed#
      # new attributes should be appended to the end.
      def has_bit_flags(attributes, options = {})
        field = options[:field] || :bit_flags

        define_singleton_method("flag_value_for") do |key|
          value = attributes[key]
          return value if value
          raise(ArgumentError, "Invalid flag: #{key}")
        end

        attributes.each do |name, value|
          define_method(name) do
            send("#{name}?")
          end

          define_method("#{name}?") do
            send(field) & value == value
          end

          define_method("#{name}_was") do
            send("#{name}_was?")
          end

          define_method("#{name}_was?") do
            send("#{field}_before_last_save") & value == value
          end

          define_method("#{name}=") do |val|
            if val.to_s =~ /[t1y]/
              send("#{field}=", send(field) | value)
            else
              send("#{field}=", send(field) & ~value)
            end
          end
        end
      end
    end
  end
end
