# frozen_string_literal: true

module ConditionalIncludes
  extend ActiveSupport::Concern

  class_methods do
    def html_includes(request, *)
      includes_if(request.format.html?, *)
    end

    def includes_if(condition, *)
      return all unless condition
      includes(*)
    end

    def includes_unless(condition, *)
      return all if condition
      includes(*)
    end
  end
end
