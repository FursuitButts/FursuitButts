# frozen_string_literal: true

module Moderator
  module Dashboard
    module Queries
      UserTextVersions = ::Struct.new(:user, :count) do
        def self.all(min_date, _max_level)
          ::UserTextVersion
            .where.not(version: 1)
            .where("user_text_versions.created_at > ?", min_date)
            .group(:updater)
            .order(Arel.sql("count(*) desc"))
            .limit(10)
            .count
            .map { |user, count| new(user, count) }
        end
      end
    end
  end
end
