# frozen_string_literal: true

module PostSets
  module Popular
    class Views < PostSets::Base
      attr_reader(:date, :limit)

      def initialize(date, limit: Reports::LIMIT)
        @date = date
        @limit = limit
      end

      def ranking
        @ranking ||= Reports.get_post_views_rank(date).first(limit)
      end

      def posts
        ::Post.where(id: ranking.pluck("post")).sort_by do |p|
          rank = ranking.find { |r| r["post"] == p.id }
          -rank["count"]
        end
      end

      def presenter
        ::PostSetPresenters::Popular::Views.new(self)
      end
    end
  end
end
