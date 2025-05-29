# frozen_string_literal: true

# Allow Rails URL helpers to be used outside of views.
#
# @example
#   Routes.posts_path(tags: "male")
#   => "/posts?tags=male"
#
# @see config/routes.rb
# @see https://guides.rubyonrails.org/routing.html
class Routes
  include(Singleton)
  include(Rails.application.routes.url_helpers)

  class << self
    delegate_missing_to(:instance)
  end
end
