module Moderator
  module DashboardsHelper
    def user_level_select_tag(name, options = {})
      choices = [
        ["", ""],
        ["Viewer", User::Levels::VIEWER],
        ["Edutir", User::Levels::EDITOR],
        ["Privileged", User::Levels::PRIVILEGED],
        ["Moderator", User::Levels::MODERATOR],
        ["Admin", User::Levels::ADMIN]
      ]

      select_tag(name, options_for_select(choices, params[name].to_i), options)
    end
  end
end
