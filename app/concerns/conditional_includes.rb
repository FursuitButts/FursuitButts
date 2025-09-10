# frozen_string_literal: true

module ConditionalIncludes
  extend(ActiveSupport::Concern)

  module ClassMethods
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

    def html_preload(request, *)
      preload_if(request.format.html?, *)
    end

    def preload_if(condition, *)
      return all unless condition
      preload(*)
    end

    def preload_unless(condition, *)
      return all if condition
      preload(*)
    end
  end
end
