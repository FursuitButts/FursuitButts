# frozen_string_literal: true

module ActiveRecordExtensions
  extend(ActiveSupport::Concern)

  module ClassMethods
    def without_timeout
      original = get_statement_timeout
      connection.execute("SET STATEMENT_TIMEOUT = 0") unless Rails.env.test?
      yield
    ensure
      connection.execute("SET STATEMENT_TIMEOUT = #{original}") unless Rails.env.test?
    end

    def with_timeout(time, default_value = nil)
      original = get_statement_timeout
      connection.execute("SET STATEMENT_TIMEOUT = #{time}") unless Rails.env.test?
      yield
    rescue ::ActiveRecord::StatementInvalid => e
      FemboyFans::Logger.log(e, expected: true)
      default_value
    ensure
      connection.execute("SET STATEMENT_TIMEOUT = #{original}") unless Rails.env.test?
    end

    def get_statement_timeout
      ApplicationRecord.connection.select_one("SELECT setting FROM pg_settings WHERE name = 'statement_timeout'")["setting"].to_i
    end
  end
end
