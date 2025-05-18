# frozen_string_literal: true

module PostSets
  module Popular
    class TopViews < PostSets::Base
      attr_reader :limit

      def initialize(limit: Reports::LIMIT)
        @limit = limit
      end

      def ranking
        @ranking ||= Reports.get_top_post_views.first(limit)
      end

      def posts
        ::Post.where(id: ranking.pluck("post")).sort_by do |p|
          rank = ranking.find { |r| r["post"] == p.id }
          -rank["count"]
        end
      end

      def presenter
        ::PostSetPresenters::Post.new(self)
      end
    end
  end
end
