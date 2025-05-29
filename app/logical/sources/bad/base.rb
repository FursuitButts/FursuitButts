# frozen_string_literal: true

module Sources
  module Bad
    class Base
      attr_reader(:sources)

      def initialize(sources)
        @sources = sources
      end

      def bad?
        false
      end
    end
  end
end
