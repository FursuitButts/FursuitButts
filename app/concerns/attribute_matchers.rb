# frozen_string_literal: true

module AttributeMatchers
  def boolean_attribute_matches(attribute, value, &)
    return all if value.nil?
    if value.to_s.truthy?
      value = true
    elsif value.to_s.falsy?
      value = false
    else
      raise(ArgumentError, "value must be truthy or falsy")
    end

    q = block_given? ? yield : all
    q.where(attribute => value)
  end

  # range: "5", ">5", "<5", ">=5", "<=5", "5..10", "5,6,7"
  def numeric_attribute_matches(attribute, value, &)
    return all if value.nil?
    value = value.to_s.strip
    column = QueryHelper.get_column(attribute, table_name)
    parsed_range = ParseValue.range(value, column.type)

    add_range_relation(parsed_range, attribute, &)
  end

  # datetime columns return ActiveSupport::TimeWithZone
  def datetime_attribute_matches(attribute, range, &)
    numeric_attribute_matches(attribute, range, &)
  end

  def add_range_relation(arr, field, &)
    return all if arr.nil?

    q = block_given? ? yield : all
    case arr[0]
    when :eq
      if arr[1].is_a?(Time)
        q.where.between(field => arr[1].all_day)
      else
        q.where(field => arr[1])
      end
    when :gt
      q.where.gt(field => arr[1])
    when :gte
      q.where.gte(field => arr[1])
    when :lt
      q.where.lt(field => arr[1])
    when :lte
      q.where.lte(field => arr[1])
    when :in
      q.where.in(field => arr[1])
    when :between
      q.where.between(field => arr[1]..arr[2])
    else
      q.none
    end
  end

  def text_attribute_matches(attribute, value, convert_to_wildcard: false, &)
    return all if value.nil?
    value = "*#{value}*" if convert_to_wildcard && value.exclude?("*")
    q = block_given? ? yield : all
    if value.is_a?(Array)
      q.where.ilike_any(attribute => value)
    elsif value =~ /\*/
      q.where.ilike(attribute => value)
    else
      q.where.tsquery(attribute => value)
    end
  end

  def ip_attribute_matches(attribute, value, &)
    return all if value.nil?

    q = block_given? ? yield : all
    q.where.inet_contained_within_or_equals(attribute => value)
  end

  def attribute_present(attribute, value, &)
    return all if value.nil?

    q = block_given? ? yield : all
    if value.to_s.truthy?
      q.where.not(attribute => nil)
    elsif value.to_s.falsy?
      q.where(attribute => nil)
    else
      q.none
    end
  end
end
