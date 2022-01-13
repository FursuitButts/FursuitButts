module Moderator
  module DashboardsHelper
    def user_level_select_tag(name, options = {})
      choices = [
        ["", ""],
        ["Member", User::Levels::MEMBER],
        ["Bitch Baby", User::Levels::BITCH_BABY],
        ["Privileged", User::Levels::PRIVILEGED],
        ["Curator", User::Levels::CURATOR],
        ["Former Staff", User::Levels::FORMER_STAFF],
        ["Janitor", User::Levels::JANITOR],
        ["Moderator", User::Levels::MODERATOR],
        ["System", User::Levels::SYSTEM],
        ["Admin", User::Levels::ADMIN]
      ]

      select_tag(name, options_for_select(choices, params[name].to_i), options)
    end
  end
end
