# frozen_string_literal: true

module Arel
  module Nodes
    class CrossJoinLateral < Arel::Nodes::Join
      def initialize(left, right = nil)
        super
      end
    end

    class LeftJoinLateral < Arel::Nodes::Join
      def initialize(left, right = nil)
        super
      end
    end
  end

  module Visitors
    class PostgreSQL
      def visit_Arel_Nodes_CrossJoinLateral(o, collector) # rubocop:disable Naming/MethodName
        collector << "CROSS JOIN LATERAL "
        visit(o.left, collector)
      end

      def visit_Arel_Nodes_LeftJoinLateral(o, collector) # rubocop:disable Naming/MethodName
        collector << "LEFT JOIN LATERAL "
        visit(o.left, collector)
        if o.right
          collector << " ON "
          visit(o.right.expr, collector)
        end
      end
    end
  end

  class Table
    def cross_join_lateral(relation)
      join(relation, Nodes::CrossJoinLateral)
    end

    def left_join_lateral(relation)
      join(relation, Nodes::LeftJoinLateral)
    end
  end
end
