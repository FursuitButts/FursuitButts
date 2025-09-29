# frozen_string_literal: true

class QueryDSL
  attr_accessor(:relation, :fields, :associations, :no_id, :no_dates)

  # [param, field, type/proc, Proc(relation)]
  def initialize(relation)
    @relation = relation
    @fields = []
    @associations = []
    @no_id = false
    @no_dates = false
  end

  def custom(param, proc, not: false, multi: false, &block)
    @fields << [param, nil, proc, block, { not: binding.local_variable_get(:not), multi: multi }]
    self
  end

  def field(param, db_field = param, type = nil, not: false, multi: false, wildcard: false, like: false, ilike: false, normalize: nil, &block)
    type ||= QueryHelper.get_column(db_field, relation.table_name).sql_type_metadata.type
    @fields << [param, db_field, type, block, { not: binding.local_variable_get(:not), multi: multi, wildcard: wildcard, like: like, ilike: ilike, normalize: normalize }]
    self
  end

  def user(param, association = nil, not: false, &)
    if param.is_a?(Array)
      raise(ArgumentError, "You must specify an association when passing an array of parameters") if association.nil?
    else
      association ||= param
      param = [:"#{param}_id", :"#{param}_name"]
    end
    association = association.to_sym
    associations = relation.reflect_on_all_associations(:belongs_to).map(&:name)
    if associations.include?(association)
      column = association_column(association)
    else
      column = association
    end
    field(param.first, column, not: binding.local_variable_get(:not), &) if param.first
    custom(param.second, ->(q, v) { q.user_name_matches(association, v) }, not: binding.local_variable_get(:not), &) if param.second
    self
  end

  def present(param, db_field = param, &)
    field(param, db_field, :present, &)
  end

  # [attribute, class, dsl, join]
  def association(*args, **kwargs)
    if args.any?
      attribute = args.first
      as = args.second || attribute
      ref = relation.reflect_on_association(attribute)
      raise("Association #{attribute} does not exist on #{relation.name}") if ref.nil?
      klass = ref.klass
      dsl = klass.query_dsl.build
      @associations << [as, klass, dsl, attribute]
      if klass == User && @fields.none? { |f| f.second == association_column(attribute) }
        user(as, attribute)
      end
    elsif kwargs.any?
      attribute = kwargs.delete(:as)
      to_array = ->(h) {
        k, v = h.first
        [k, v.is_a?(Hash) ? to_array.call(v) : v].flatten
      }
      through = to_array.call(kwargs)
      attribute ||= through.last
      klass = relation
      through.each { |k| klass = klass.reflect_on_association(k).klass }
      dsl = klass.query_dsl.build
      join = through.reverse.reduce { |acc, key| { key => acc } }
      @associations << [attribute, klass, dsl, join]
    else
      raise(ArgumentError, "Missing association")
    end
    self
  end

  def no_id!
    @no_id = true
    @fields.reject! { |field| field.first == :id }
    self
  end

  def no_dates!
    @no_dates = true
    @fields.reject! { |field| %i[created_at updated_at].include?(field.first) }
    self
  end

  def build
    @fields << %i[id id integer] if @fields.none? { |field| field.first == :id }
    @fields << %i[created_at created_at datetime] if @fields.none? { |field| field.first == :created_at } && relation.attribute_names.include?("created_at")
    @fields << %i[updated_at updated_at datetime] if @fields.none? { |field| field.first == :updated_at } && relation.attribute_names.include?("updated_at")
    {
      fields:       fields,
      associations: associations,
    }
  end

  private

  def association_column(association)
    :"#{relation.table_name}.#{relation.reflect_on_association(association).foreign_key}"
  end
end
