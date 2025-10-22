# frozen_string_literal: true

module WhereChainExtensions
  %i[
    lt lteq gt gteq
    between not_between in not_in like
    ilike not_like not_ilike
    like_all ilike_all not_like_all not_ilike_all
    like_any ilike_any not_like_any not_ilike_any
    has_bits not_has_bits
  ].each do |method|
    define_method(method) do |conditions|
      build(conditions, method)
    end
  end

  alias lte lteq
  alias gte gteq

  # https://www.postgresql.org/docs/current/static/functions-matching.html#FUNCTIONS-POSIX-REGEXP
  # "(?e)" means force use of ERE syntax; see sections 9.7.3.1 and 9.7.3.4.
  def regex(conditions = {}, flags: "e", **kwargs)
    conditions.merge!(kwargs) if conditions.is_a?(Hash)
    build(conditions, :regex, flags)
  end

  def not_regex(conditions = {}, flags: "e", **kwargs)
    conditions.merge!(kwargs) if conditions.is_a?(Hash)
    build(conditions, :not_regex, flags)
  end

  def tsquery(conditions = {}, ts_config: "english", **kwargs)
    conditions.merge!(kwargs) if conditions.is_a?(Hash)
    build(conditions, :tsquery, ts_config)
  end

  METHODS = {
    lt:            ->(table_name, column, value) { Arel::Table.new(table_name)[column].lt(value) },
    lteq:          ->(table_name, column, value) { Arel::Table.new(table_name)[column].lteq(value) },
    gt:            ->(table_name, column, value) { Arel::Table.new(table_name)[column].gt(value) },
    gteq:          ->(table_name, column, value) { Arel::Table.new(table_name)[column].gteq(value) },
    between:       ->(table_name, column, value) { Arel::Table.new(table_name)[column].between(value) },
    not_between:   ->(table_name, column, value) { Arel::Table.new(table_name)[column].not_between(value) },
    in:            ->(table_name, column, value) { Arel::Table.new(table_name)[column].in(value) },
    not_in:        ->(table_name, column, value) { Arel::Table.new(table_name)[column].not_in(value) },
    like:          ->(table_name, column, value) { Arel::Table.new(table_name)[column].matches(value.to_escaped_for_sql_like, Arel.sql("E'\\\\'"), true) },
    ilike:         ->(table_name, column, value) { Arel::Table.new(table_name)[column].matches(value.to_escaped_for_sql_like, Arel.sql("E'\\\\'"), false) },
    not_like:      ->(table_name, column, value) { Arel::Table.new(table_name)[column].does_not_match(value.to_escaped_for_sql_like, Arel.sql("E'\\\\'"), true) },
    not_ilike:     ->(table_name, column, value) { Arel::Table.new(table_name)[column].does_not_match(value.to_escaped_for_sql_like, Arel.sql("E'\\\\'"), false) },
    like_all:      ->(table_name, column, value) { Arel::Table.new(table_name)[column].matches_all(value.map(&:to_escaped_for_sql_like), Arel.sql("E'\\\\'"), true) },
    ilike_all:     ->(table_name, column, value) { Arel::Table.new(table_name)[column].matches_all(value.map(&:to_escaped_for_sql_like), Arel.sql("E'\\\\'"), false) },
    not_like_all:  ->(table_name, column, value) { Arel::Table.new(table_name)[column].does_not_match_all(value.map(&:to_escaped_for_sql_like), Arel.sql("E'\\\\'"), true) },
    not_ilike_all: ->(table_name, column, value) { Arel::Table.new(table_name)[column].does_not_match_all(value.map(&:to_escaped_for_sql_like), Arel.sql("E'\\\\'"), false) },
    like_any:      ->(table_name, column, value) { Arel::Table.new(table_name)[column].matches_any(value.map(&:to_escaped_for_sql_like), Arel.sql("E'\\\\'"), true) },
    ilike_any:     ->(table_name, column, value) { Arel::Table.new(table_name)[column].matches_any(value.map(&:to_escaped_for_sql_like), Arel.sql("E'\\\\'"), false) },
    not_like_any:  ->(table_name, column, value) { Arel::Table.new(table_name)[column].does_not_match_any(value.map(&:to_escaped_for_sql_like), Arel.sql("E'\\\\'"), true) },
    not_ilike_any: ->(table_name, column, value) { Arel::Table.new(table_name)[column].does_not_match_any(value.map(&:to_escaped_for_sql_like), Arel.sql("E'\\\\'"), false) },
    regex:         ->(table_name, column, value, flags) { Arel::Table.new(table_name)[column].matches_regexp("(?#{flags})#{value.is_a?(Regexp) ? value.source : value}") },
    not_regex:     ->(table_name, column, value, flags) { Arel::Table.new(table_name)[column].does_not_match_regexp("(?#{flags})#{value.is_a?(Regexp) ? value.source : value}") },
    tsquery:       ->(table_name, column, value, ts_config) { Arel.sql("to_tsvector(:ts_config, :table) @@ plainto_tsquery(:ts_config, :value)", ts_config: ts_config, value: value, table: Arel.sql("#{table_name}.#{column}")) },
    has_bits:      ->(table_name, column, value) { Arel.sql("(#{table_name}.#{column} & #{Arel::Nodes.build_quoted(value).to_sql}) = #{Arel::Nodes.build_quoted(value).to_sql}") },
    not_has_bits:  ->(table_name, column, value) { Arel.sql("(#{table_name}.#{column} & #{Arel::Nodes.build_quoted(value).to_sql}) != #{Arel::Nodes.build_quoted(value).to_sql}") },
  }.freeze

  private

  def build(conditions, method, *extra)
    model = @scope.klass

    parsed_conditions = normalize_conditions(conditions, model)

    arel_conditions = parsed_conditions.map do |(table_name, column), value|
      METHODS.fetch(method).call(table_name, column, value, *extra)
    end.reduce(:and)

    @scope.where(arel_conditions)
  end

  def normalize_conditions(conditions, model, table_name = nil)
    pairs = []

    conditions.each do |key, value|
      case key
      when String, Symbol
        key = key.to_s
        if value.is_a?(Hash)
          pairs.concat(normalize_conditions(value, model, key))
        elsif key.include?(".")
          table, col = key.split(".", 2)
          pairs << [[table, col], value]
        else
          pairs << [[table_name || model.table_name, key], value]
        end
      else
        raise(ArgumentError, "Unsupported key type: #{key.class}")
      end
    end

    pairs
  end
end

ActiveRecord::QueryMethods::WhereChain.include(WhereChainExtensions)
