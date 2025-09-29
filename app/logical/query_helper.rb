# frozen_string_literal: true

module QueryHelper
  module_function

  def parse_conditions(conditions, model, table_name = nil)
    pairs = []

    conditions.each do |key, value|
      case key
      when String, Symbol
        key = key.to_s
        if value.is_a?(Hash)
          pairs.concat(parse_conditions(value, model, key))
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

  def get_column(attribute, table = nil)
    attribute = attribute.to_s
    if attribute.include?(".")
      table, column = attribute.split(".", 2)
    else
      column = attribute
    end
    raise(ArgumentError, "Missing table") if table.nil?
    c = ActiveRecord::Base.connection.columns(table).find { |c| c.name == column }
    raise(StandardError, "Column #{column} does not exist in table #{table}") unless c
    c
  rescue ActiveRecord::StatementInvalid
    raise(StandardError, "Table #{table} does not exist")
  end
end
