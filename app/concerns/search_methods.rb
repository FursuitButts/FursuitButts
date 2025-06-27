# frozen_string_literal: true

module SearchMethods
  extend(ActiveSupport::Concern)

  module ClassMethods
    def paginate(page, options = {})
      extending(FemboyFans::Paginator::ActiveRecordExtension).paginate(page, options)
    end

    def paginate_posts(page, options = {})
      options[:user] ||= User.anonymous
      extending(FemboyFans::Paginator::ActiveRecordExtension).paginate_posts(page, options)
    end

    def qualified_column_for(attr)
      "#{table_name}.#{column_for_attribute(attr).name}"
    end

    def where_like(attr, value)
      where("#{qualified_column_for(attr)} LIKE ? ESCAPE E'\\\\'", value.to_escaped_for_sql_like)
    end

    def where_ilike(attr, value)
      where("lower(#{qualified_column_for(attr)}) LIKE ? ESCAPE E'\\\\'", value.downcase.to_escaped_for_sql_like)
    end

    # https://www.postgresql.org/docs/current/static/functions-matching.html#FUNCTIONS-POSIX-REGEXP
    # "(?e)" means force use of ERE syntax; see sections 9.7.3.1 and 9.7.3.4.
    def where_regex(attr, value, flags: "e")
      where(arel_table[attr].matches_regexp("(?#{flags})" + value))
    end

    def where_not_regex(attr, value, flags: "e")
      where(arel_table[attr].does_not_match_regexp("(?#{flags})" + value))
    end

    def attribute_exact_matches(attribute, value, **_options)
      return all if value.blank?

      column = qualified_column_for(attribute)
      where("#{column} = ?", value)
    end

    def attribute_matches(attribute, value, **)
      return all if value.nil?

      column = column_for_attribute(attribute)
      case column.sql_type_metadata.type
      when :boolean
        boolean_attribute_matches(attribute, value)
      when :integer, :datetime
        numeric_attribute_matches(attribute, value)
      when :string, :text
        text_attribute_matches(attribute, value, **)
      else
        raise(ArgumentError, "unhandled attribute type")
      end
    end

    def boolean_attribute_matches(attribute, value)
      if value.to_s.truthy?
        value = true
      elsif value.to_s.falsy?
        value = false
      else
        raise(ArgumentError, "value must be truthy or falsy")
      end

      where(attribute => value)
    end

    # range: "5", ">5", "<5", ">=5", "<=5", "5..10", "5,6,7"
    def numeric_attribute_matches(attribute, range)
      column = column_for_attribute(attribute)
      qualified_column = "#{table_name}.#{column.name}"
      parsed_range = ParseValue.range(range, column.type)

      add_range_relation(parsed_range, qualified_column)
    end

    # datetime columns return ActiveSupport::TimeWithZone
    def datetime_attribute_matches(attribute, range)
      numeric_attribute_matches(attribute, range.to_i)
    end

    def add_range_relation(arr, field)
      return all if arr.nil?

      case arr[0]
      when :eq
        if arr[1].is_a?(Time)
          where("#{field} between ? and ?", arr[1].beginning_of_day, arr[1].end_of_day)
        else
          where(["#{field} = ?", arr[1]])
        end
      when :gt
        where(["#{field} > ?", arr[1]])
      when :gte
        where(["#{field} >= ?", arr[1]])
      when :lt
        where(["#{field} < ?", arr[1]])
      when :lte
        where(["#{field} <= ?", arr[1]])
      when :in
        where(["#{field} in (?)", arr[1]])
      when :between
        where(["#{field} BETWEEN ? AND ?", arr[1], arr[2]])
      else
        all
      end
    end

    def
      text_attribute_matches(attribute, value, convert_to_wildcard: false)
      column = column_for_attribute(attribute)
      qualified_column = "#{table_name}.#{column.name}"
      value = "*#{value}*" if convert_to_wildcard && value.exclude?("*")

      if value =~ /\*/
        where("lower(#{qualified_column}) LIKE :value ESCAPE E'\\\\'", value: value.downcase.to_escaped_for_sql_like)
      else
        where("to_tsvector(:ts_config, #{qualified_column}) @@ plainto_tsquery(:ts_config, :value)", ts_config: "english", value: value)
      end
    end

    def with_resolved_user_ids(query_field, params, &)
      user_name_key = query_field.is_a?(Symbol) ? "#{query_field}_name" : query_field[0]
      user_id_key = query_field.is_a?(Symbol) ? "#{query_field}_id" : query_field[1]

      if params[user_name_key].present?
        user_ids = [User.name_to_id(params[user_name_key]) || 0]
      end
      if params[user_id_key].present?
        user_ids = params[user_id_key].split(",").first(100).map(&:to_i)
      end

      yield(user_ids) if user_ids
    end

    # Searches for a user both by id and name.
    # Accepts a block to modify the query when one of the params is present and yields the ids.
    def where_user(db_field, query_field, params)
      q = all
      with_resolved_user_ids(query_field, params) do |user_ids|
        q = yield(q, user_ids) if block_given?
        q = q.where(to_where_hash(db_field, user_ids))
      end
      q
    end

    def apply_basic_order(params)
      case params[:order]
      when "id_asc"
        order(id: :asc)
      when "id_desc"
        order(id: :desc)
      else
        default_order
      end
    end

    def default_order
      order(id: :desc)
    end

    def search(params, user, visible: true)
      params ||= {}

      unless (params.is_a?(ActionController::Parameters) || params.is_a?(Hash)) && user.is_a?(UserLike)
        raise(ArgumentError, "search expects (HashLike, UserLike), got (#{params.class}, #{user.class})")
      end

      q = all
      q = q.visible(user) if visible
      q = q.attribute_matches(:id, params[:id])
      q = q.attribute_matches(:created_at, params[:created_at]) if attribute_names.include?("created_at")
      q = q.attribute_matches(:updated_at, params[:updated_at]) if attribute_names.include?("updated_at")

      q
    end

    private

    # to_where_hash(:a, 1) => { a: 1 }
    # to_where_hash(a: :b, 1) => { a: { b: 1 } }
    def to_where_hash(field, value)
      if field.is_a?(Symbol)
        { field => value }
      elsif field.is_a?(Hash) && field.size == 1 && field.values.first.is_a?(Symbol)
        { field.keys.first => { field.values.first => value } }
      else
        raise(StandardError, "Unsupported field: #{field.class} => #{field}")
      end
    end
  end
end
