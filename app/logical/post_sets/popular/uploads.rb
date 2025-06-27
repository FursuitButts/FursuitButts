# frozen_string_literal: true

module PostSets
  module Popular
    class Uploads < PostSets::Base
      attr_reader(:date, :scale, :min_date, :max_date, :limit)

      def initialize(date, scale, min_date, max_date, current_user:, limit: nil)
        super(current_user)
        @date = date
        @scale = scale
        @min_date = min_date
        @max_date = max_date
        @limit = limit || current_user.per_page
      end

      def posts
        @posts ||= begin
          query = ::Post.where(created_at: min_date..max_date).order(score: :desc).limit(limit)
          query.each # HACK: to force rails to eager load
          query
        end
      end

      def presenter
        ::PostSetPresenters::Popular::Uploads.new(self)
      end
    end
  end
end
