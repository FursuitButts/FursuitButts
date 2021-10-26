module Moderator
  module DashboardsHelper
    def user_level_select_tag(name, options = {})
      choices = [
        ["", ""],
        ["Viewer", User::Levels::VIEWER],
        ["Editor", User::Levels::EDITOR],
        ["Privileged", User::Levels::PRIVILEGED],
        ["Former Staff", User::Levels::FORMER_STAFF],
        ["Admin", User::Levels::ADMIN]
      ]

      select_tag(name, options_for_select(choices, params[name].to_i), options)
    end
  end
end
