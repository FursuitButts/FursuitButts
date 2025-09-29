# frozen_string_literal: true

class UserAttribute
  class CircularAliasError < StandardError; end
  class CircularCloneError < StandardError; end
  class DuplicateAttributeError < StandardError; end
  class CloneError < StandardError; end
  attr_reader(:klass, :attribute, :db, :ip, :optional, :clones, :overwrite, :aliases, :ignore_nil, :ar_options)

  def initialize(klass, attribute, db:, ip: !db, optional: !db, clones: [], overwrite: false, aliases: [], ignore_nil: false, **ar_options)
    UserAttribute.class_setup(klass)
    @klass = klass
    @attribute = attribute.to_sym
    @db = db
    # noinspection RubySimplifyBooleanInspection
    @ip = ip == true ? :"#{attribute}_ip_addr" : ip
    @optional = optional
    @clones = Array(clones).map(&:to_sym)
    @overwrite = overwrite
    @aliases = Array(aliases).map(&:to_sym)
    @ignore_nil = ignore_nil
    @ar_options = ar_options
    if ar_options.any? && !db
      TraceLogger.warn("UserAttribute", "Unexpected extra options for non-db attribute: #{ar_options.inspect}", ignore: [%r{/concerns/user_methods\.rb}, %r{/logical/user_attribute\.rb}])
    end
    @ar_options[:optional] = optional
    @ar_options[:class_name] = "User"
    validate_options!
    klass.user_attributes[attribute] = self
    define_methods
  end

  def validate_options!
    raise(DuplicateAttributeError, "user attribute #{attribute} is already defined on #{klass}") if klass.user_attributes.key?(attribute)
    validate_aliases!
    validate_clones!
  end

  def validate_aliases!
    return if aliases.empty?
    raise(CircularAliasError, "aliases must not contain attribute (#{klass}.#{attribute}") if aliases.include?(attribute)
  end

  def validate_clones!
    return if clones.empty?
    raise(CircularCloneError, "clones must not contain attribute (#{klass}.#{attribute}") if clones.include?(attribute)
    # TODO
  end

  def validate_value!(value, type, record: nil)
    return if value.nil?
    case type
    when :user
      return if (optional || ignore_nil) && value.nil?
      return if value.is_a?(User)
      if value.is_a?(UserResolvable)
        return if value.user.is_a?(User)
        raise(ArgumentError, "Expected User for UserResolvable.user in #{klass.name}##{attribute}, got #{value.user.inspect} (#{value.user.class.name})")
      end
      value_error("is invalid", "UserLike", attribute, value, record: record)
    when :id
      value_error("is invalid", "Integer", "#{attribute}_id", value, record: record) unless value.is_a?(Integer) || (value.is_a?(String) && /\A\d+\Z/.match?(value))
    when :name
      value_error("is invalid", "String", "#{attribute}_name", value, record: record) unless value.is_a?(String)
    when :ip_addr
      return if value.is_a?(IPAddr)
      begin
        IPAddr.new(value)
      rescue IPAddr::InvalidAddressError
        value_error("is invalid", "IPAddr", ip, value, record: record)
      end
    else
      raise(ArgumentError, "Not sure how to validate #{type}")
    end
  end

  def value_error(message, expected, attr, value, record: nil)
    if record.respond_to?(:errors) && record.errors.is_a?(ActiveModel::Errors)
      record.errors.add(attr, message)
    else
      raise(ArgumentError, "Expected #{expected} for #{klass.name}.#{attr}=, got #{value.inspect} (#{value.class.name})")
    end
  end

  def define_methods
    ua = self
    klass.define_singleton_method(:"#{attribute}_attribute") { ua }
    klass.belongs_to(attribute, **ar_options) if db
    if (klass < ActiveModel::Validations) && ip && !optional
      # klass.validates(attribute, presence: { message: "must exist" }) unless optional
      klass.validates(ip, presence: true, if: -> { send("#{ua.attribute}_id").present? })
    end
    klass.define_method(attribute) do
      if ua.db
        value = super()
      else
        value = instance_variable_get(:"@#{ua.attribute}")
        value = ua.get_clone_value(self) if value.blank?
      end
      return if value.blank?

      if ua.ip && (ip_addr = send(ua.ip))
        UserResolvable.new(value, ip_addr)
      else
        value
      end
    end
    klass.define_method("#{attribute}=") do |value|
      ua.validate_value!(value, :user, record: self)
      if ua.clones.any?
        ua.clones.each do |cattr|
          ua.clone_value(self, cattr, value)
        end
      end

      if value.is_a?(UserResolvable)
        send("#{ua.ip}=", value.ip_addr) if ua.ip
        value = value.user
      end

      if ua.db
        super(value)
      else
        instance_variable_set(:"@#{ua.attribute}", value)
      end
    end
    klass.define_method("#{attribute}_id") do
      if ua.db
        read_attribute("#{ua.attribute}_id")
      else
        value = instance_variable_get(:"@#{ua.attribute}")&.id
        value = ua.get_clone_value(self, :id) if value.blank?
        value
      end
    end
    klass.define_method("#{attribute}_id=") do |value|
      ua.validate_value!(value, :id, record: self)
      if ua.db
        write_attribute("#{ua.attribute}_id", value)
        TraceLogger.warn("UserAttribute", "#{ua.klass.name}.#{ua.attribute}_id= should not be used when clone is enabled (#{ua.clones.join(', ')})", ignore: [%r{/concerns/user_methods\.rb}, %r{/logical/user_attribute\.rb}]) if ua.clones.any?
      else
        value = User.find(value) if value.is_a?(Integer) || value.is_a?(String)
        ua.clones.each do |cattr|
          ua.clone_direct(self, cattr, value)
        end
        instance_variable_set(:"@#{ua.attribute}", value)
      end
    end
    klass.define_method("#{attribute}_name") do
      value = send("#{ua.attribute}_id")
      return "Anonymous" if value.blank?
      User.id_to_name(value)
    end
    klass.define_method("#{attribute}_name=") do |value|
      ua.validate_value!(value, :name, record: self)
      value = User.name_to_id(value)
      return send("#{ua.attribute}_id=", value) if value.blank?
      send("#{ua.attribute}=", User.find(value))
    end
    if ip
      klass.define_method(ip) do
        if ua.db
          read_attribute(ua.ip)
        else
          value = instance_variable_get(:"@#{ua.ip}")
          value = ua.get_clone_value(self, :ip_addr) if value.blank?
          value
        end
      end
      klass.define_method("#{ip}=") do |value|
        ua.validate_value!(value, :ip_addr, record: self)
        if ua.db
          write_attribute(ua.ip, value)
        else
          value = value.to_s.strip if value.is_a?(String)
          ua.clones.each do |cattr|
            ua.clone_ip(self, cattr, value)
          end
          instance_variable_set(:"@#{ua.ip}", value)
        end
      end
    end
    klass.instance_exec do
      scope("for_#{ua.attribute}", ->(value) { where(ua.db && ua.ar_options.key?(:foreign_key) ? ua.ar_options[:foreign_key] : "#{ua.attribute}_id" => u2id(value)) }) unless respond_to?("for_#{ua.attribute}")
      scope("for_#{ua.attribute}_id", ->(value) { where(ua.db && ua.ar_options.key?(:foreign_key) ? ua.ar_options[:foreign_key] : "#{ua.attribute}_id" => value) }) unless respond_to?("for_#{ua.attribute}_id")
      scope("for_#{ua.attribute}_name", ->(value) { where(ua.db && ua.ar_options.key?(:foreign_key) ? ua.ar_options[:foreign_key] : "#{ua.attribute}_id" => User.name_to_id(value)) }) unless respond_to?("for_#{ua.attribute}_name")
    end

    aliases.each do |alias_attr|
      create_alias(alias_attr)
    end
  end

  def get_clone_value(record, type = nil)
    attrs = klass.user_attributes.select { |_attr, options| options.clones.include?(attribute) }
    value = nil
    attrs.each_key do |cattr|
      case type
      when :id
        value = record.send("#{cattr}_id")
      when :ip_addr
        value = record.send(attrs[cattr].ip) if attrs[cattr].ip
      else
        value = record.send(cattr)
      end
      break if value.present?
    end
    value
  end

  def clone_value(record, attr, value)
    return record.send("#{attr}=", value) if overwrite
    if record.respond_to?(:"#{attr}_id")
      record.send(:"#{attr}=", value) if record.send(:"#{attr}_id").blank?
    elsif record.respond_to?(attr)
      record.send(:"#{attr}=", value) if record.send(attr).blank?
    else
      raise(CloneError, "Not sure how to clone to #{attr}, #{record.class} does not respond_to? #{attr}_id or #{attr}")
    end
  end

  def clone_ip(record, attr, value)
    ip_attr = klass.user_attributes.find { |uattr, _value| uattr == attr }&.second&.ip
    raise(CloneError, "Not sure how to clone ip for #{attr}, no ip attribute defined") unless ip_attr
    clone_direct(record, ip_attr, value)
  end

  def clone_direct(record, attr, value)
    return record.send("#{attr}=", value) if overwrite
    if record.respond_to?(attr)
      record.send(:"#{attr}=", value) if record.send(attr).blank?
    else
      raise(CloneError, "Not sure how to clone to #{attr}, #{record.class} does not respond_to? #{attr}")
    end
  end

  def create_alias(attr)
    ua = self
    klass.class_eval do
      define_method(attr) { send(ua.attribute) }
      define_method("#{attr}=") { |value| send("#{ua.attribute}=", value) }
      define_method("#{attr}_id") { send("#{ua.attribute}_id") }
      define_method("#{attr}_id=") { |value| send("#{ua.attribute}_id=", value) }
      define_method("#{attr}_name") { send("#{ua.attribute}_name") }
      define_method("#{attr}_name=") { |value| send("#{ua.attribute}_name=", value) }
      if ua.ip
        define_method("#{attr}_ip_addr") { send(ua.ip) }
        define_method("#{attr}_ip_addr=") { |value| send("#{ua.ip}=", value) }
      end
    end
  end

  def self.class_setup(klass)
    return if klass.method_defined?(:user_attributes)
    klass.class_eval do
      class_attribute(:user_attributes, default: {})
    end
  end
end
