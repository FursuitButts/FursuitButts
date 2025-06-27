# frozen_string_literal: true

module AttributeMethods
  extend(ActiveSupport::Concern)

  module ClassMethods
    # Defines `<attribute>_string`, `<attribute>_string=`, and `<attribute>=`
    # methods for converting an array attribute to or from a string.
    #
    # The `<attribute>=` setter parses strings into an array using the
    # `parse` regex. The resulting strings can be converted to another type
    # with the `cast` option.
    def array_attribute(name, parse: /[^[:space:]]+/, join_character: " ", cast: :itself)
      define_method("#{name}_string") do
        send(name).join(join_character)
      end

      define_method("#{name}_string=") do |value|
        raise(ArgumentError, "#{name} must be a String") unless value.respond_to?(:to_str)
        send("#{name}=", value)
      end

      define_method("#{name}=") do |value|
        if value.respond_to?(:to_str)
          super(value.to_str.scan(parse).flatten.map(&cast))
        elsif value.respond_to?(:to_a)
          super(value.to_a)
        else
          raise(ArgumentError, "#{name} must be a String or an Array")
        end
      end
    end
  end
end
