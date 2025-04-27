# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_create -> { DiscordNotification.new(self, :create).execute! }
  after_update -> { DiscordNotification.new(self, :update).execute! }
  after_destroy -> { DiscordNotification.new(self, :destroy).execute! }

  concerning :SearchMethods do
    class_methods do
      def paginate(page, options = {})
        extending(FemboyFans::Paginator::ActiveRecordExtension).paginate(page, options)
      end

      def paginate_posts(page, options = {})
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

      def search(params)
        params ||= {}

        q = all
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

  module ApiMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def available_includes
        []
      end

      def multiple_includes
        reflections.select { |_, v| v.macro == :has_many }.keys.map(&:to_sym)
      end

      def associated_models(name)
        if reflections[name].options[:polymorphic]
          reflections[name].active_record.try(:model_types) || []
        else
          [reflections[name].class_name]
        end
      end
    end

    def available_includes
      self.class.available_includes
    end

    # XXX deprecated, shouldn't expose this as an instance method.
    def api_attributes(user: CurrentUser.user)
      policy = Pundit.policy(user, self) || ApplicationPolicy.new(user, self)
      policy.api_attributes
    end

    # XXX deprecated, shouldn't expose this as an instance method.
    def html_data_attributes(user: CurrentUser.user)
      policy = Pundit.policy(user, self) || ApplicationPolicy.new(user, self)
      policy.html_data_attributes
    end

    def process_api_attributes(options, underscore: false)
      options[:methods] ||= []
      attributes, methods = api_attributes.partition { |attr| has_attribute?(attr) }
      methods += options[:methods]
      if underscore && options[:only].blank?
        options[:only] = attributes + methods
      else
        options[:only] ||= attributes + methods
      end

      attributes &= options[:only]
      methods &= options[:only]

      options[:only] = attributes
      options[:methods] = methods

      options.delete(:methods) if options[:methods].empty?
      options
    end

    def serializable_hash(options = {})
      options ||= {}
      return :not_visible unless visible?
      if options[:only].is_a?(String)
        options.delete(:methods)
        options.delete(:include)
        options.merge!(ParameterBuilder.serial_parameters(options[:only], self))
        if options[:only].include?("_")
          options[:only].delete("_")
          options = process_api_attributes(options, underscore: true)
        end
      else
        options = process_api_attributes(options)
      end
      options[:only] += [SecureRandom.hex(6)]

      hash = super(options)
      hash.transform_keys! { |key| key.delete("?") }
      deep_reject_hash(hash) { |_, v| v == :not_visible }
    end

    def visible?(_user = CurrentUser.user)
      true
    end

    def deep_reject_hash(hash, &block)
      hash.each_with_object({}) do |(key, value), result|
        if value.is_a?(Hash)
          result[key] = deep_reject_hash(value, &block)
        elsif value.is_a?(Array)
          result[key] = value.map { |v| v.is_a?(Hash) ? deep_reject_hash(v, &block) : v }.reject { |i| block.call(nil, i) }
        elsif !block.call(key, value)
          result[key] = value
        end
      end
    end
  end

  concerning :ActiveRecordExtensions do
    class_methods do
      def without_timeout
        connection.execute("SET STATEMENT_TIMEOUT = 0") unless Rails.env.test?
        yield
      ensure
        connection.execute("SET STATEMENT_TIMEOUT = #{CurrentUser.user.try(:statement_timeout) || 3_000}") unless Rails.env.test?
      end

      def with_timeout(time, default_value = nil)
        connection.execute("SET STATEMENT_TIMEOUT = #{time}") unless Rails.env.test?
        yield
      rescue ::ActiveRecord::StatementInvalid => e
        FemboyFans::Logger.log(e, expected: true)
        default_value
      ensure
        connection.execute("SET STATEMENT_TIMEOUT = #{CurrentUser.user.try(:statement_timeout) || 3_000}") unless Rails.env.test?
      end
    end
  end

  concerning :SimpleVersioningMethods do
    class_methods do
      def simple_versioning(options = {})
        cattr_accessor(:versioning_body_column, :versioning_ip_column, :versioning_user_column, :versioning_subject_column, :versioning_is_hidden_column, :versioning_is_sticky_column)
        self.versioning_body_column = options[:body_column] || "body"
        self.versioning_subject_column = options[:subject_column]
        self.versioning_ip_column = options[:ip_column] || "creator_ip_addr"
        self.versioning_user_column = options[:user_column] || "creator_id"
        self.versioning_is_hidden_column = options[:is_hidden_column] || "is_hidden"
        self.versioning_is_sticky_column = options[:is_sticky_column] || "is_sticky"

        class_eval do
          has_many(:versions, class_name: "EditHistory", as: :versionable)
          after_update(:save_version, if: :should_create_edited_history)
          after_save(if: :should_create_hidden_history) do |rec|
            type = rec.send("#{versioning_is_hidden_column}?") ? "hide" : "unhide"
            save_version(type)
          end
          after_save(if: :should_create_stickied_history) do |rec|
            type = rec.send("#{versioning_is_sticky_column}?") ? "stick" : "unstick"
            save_version(type)
          end

          define_method(:should_create_edited_history) do
            return true if versioning_subject_column && saved_change_to_attribute?(versioning_subject_column)
            saved_change_to_attribute?(versioning_body_column)
          end

          define_method(:should_create_hidden_history) do
            saved_change_to_attribute?(versioning_is_hidden_column)
          end

          define_method(:should_create_stickied_history) do
            saved_change_to_attribute?(versioning_is_sticky_column)
          end

          define_method(:save_original_version) do
            body = send("#{versioning_body_column}_before_last_save")
            body = send(versioning_body_column) if body.nil?

            subject = nil
            if versioning_subject_column
              subject = send("#{versioning_subject_column}_before_last_save")
              subject = send(versioning_subject_column) if subject.nil?
            end
            new = EditHistory.new
            new.versionable = self
            new.version = 1
            new.ip_addr = send(versioning_ip_column)
            new.body = body
            new.user_id = send(versioning_user_column)
            new.subject = subject
            new.created_at = created_at
            new.save!
          end

          define_method(:save_version) do |edit_type = "edit", extra_data = {}|
            EditHistory.transaction do
              our_next_version = next_version
              if our_next_version == 0
                save_original_version
                our_next_version += 1
              end

              body = send(versioning_body_column)
              subject = versioning_subject_column ? send(versioning_subject_column) : nil

              version = EditHistory.new
              version.version = our_next_version + 1
              version.versionable = self
              version.ip_addr = CurrentUser.ip_addr
              version.body = body
              version.subject = subject
              version.user_id = CurrentUser.id
              version.edit_type = edit_type
              version.extra_data = extra_data
              version.save!
            end
          end

          define_method(:next_version) do
            versions.count
          end
        end
      end
    end
  end

  concerning :MentionableMethods do
    class_methods do
      def mentionable(options = {})
        cattr_accessor(:mentionable_body_column, :mentionable_notified_mentions_column, :mentionable_creator_column)
        self.mentionable_body_column = options[:body_column] || "body"
        self.mentionable_notified_mentions_column = options[:notified_mentions_column] || "notified_mentions"
        self.mentionable_creator_column = options[:user_column] || "creator_id"

        class_eval do
          after_save(:update_mentions, if: :should_update_mentions?)

          define_method(:should_update_mentions?) do
            saved_change_to_attribute?(mentionable_body_column) && CurrentUser.user.id == send(mentionable_creator_column) # && send(mentionable_creator_column) != User.system.id
          end

          define_method(:update_mentions) do
            return unless should_update_mentions?

            DText.parse(send(mentionable_body_column)) => { mentions: }
            return if mentions.empty?
            sent = mentionable_notified_mentions_column.present? && respond_to?(mentionable_notified_mentions_column) ? send(mentionable_notified_mentions_column) : []
            userids = mentions.uniq.map { |name| User.name_to_id(name) }.compact.uniq
            unsent = userids - sent
            creator = send(mentionable_creator_column)
            return if unsent.empty?
            unsent.each do |user_id|
              # Save the user to the mentioned list regardless so they don't get a random notification for a future edit if they unblock the creator
              send(mentionable_notified_mentions_column) << user_id if mentionable_notified_mentions_column.present? && respond_to?(mentionable_notified_mentions_column)
              user = User.find(user_id)
              next if user.is_suppressing_mentions_from?(creator) || user.id == creator || user == User.system
              extra = {}
              type = self.class.name
              case type
              when "Comment"
                extra[:post_id] = post_id
              when "ForumPost"
                extra[:topic_id] = topic_id
                extra[:topic_title] = topic.title
              end
              user.notifications.create!(category: "mention", data: { mention_id: id, mention_type: type, user_id: creator, **extra })
            end
            save
          end

          define_method(:mentions) do
            notified_mentions.map { |id| { id: id, name: User.id_to_name(id) } }
          end
        end
      end
    end
  end

  concerning :UserMethods do
    class_methods do
      def belongs_to_creator(options = {})
        class_eval do
          belongs_to(:creator, **options.merge(class_name: "User"))
          before_validation(:__set_creator__, on: :create)

          define_method(:creator_name) do
            return creator.name if association(:creator).loaded?
            User.id_to_name(creator_id)
          end

          define_method(:__set_creator__) do
            self.creator_id = CurrentUser.id if creator_id.nil?
            self.creator_ip_addr = CurrentUser.ip_addr if respond_to?(:creator_ip_addr=) && creator_ip_addr.nil?
          end
        end
      end

      def belongs_to_updater(options = {})
        class_eval do
          belongs_to(:updater, **options.merge(class_name: "User"))
          before_validation(:__set_updater__, unless: :destroyed?)

          define_method(:updater_name) do
            return updater.name if association(:updater).loaded?
            User.id_to_name(updater_id)
          end

          define_method(:__set_updater__) do
            self.updater_id = CurrentUser.id
            self.updater_ip_addr = CurrentUser.ip_addr if respond_to?(:updater_ip_addr=)
          end
        end
      end
    end
  end

  concerning :AttributeMethods do
    class_methods do
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

  concerning :PrivilegeMethods do
    class_methods do
      def visible(_user)
        all
      end

      def visible_for_search(attribute, current_user)
        policy(current_user).visible_for_search(all, attribute)
      end

      def policy(current_user)
        Pundit.policy(current_user, self)
      end
    end

    def policy(current_user)
      Pundit.policy(current_user, self)
    end
  end

  def warnings
    @warnings ||= ActiveModel::Errors.new(self)
  end

  include HasDtextLinks
  include ApiMethods
  include ConditionalIncludes
  include HasMediaAsset

  def self.override_route_key(value)
    define_singleton_method(:model_name) do
      mn = ActiveModel::Name.new(self)
      mn.instance_variable_set(:@route_key, value)
      mn
    end
  end

  def html_data_attributes(user = CurrentUser.user)
    policy = Pundit.policy(user, self) || ApplicationPolicy.new(user, self)
    policy.html_data_attributes
  end
end
