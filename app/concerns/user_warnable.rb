# frozen_string_literal: true

module UserWarnable
  extend(ActiveSupport::Concern)

  included do
    enum(:warning_type, {
      warning: 1,
      record:  2,
      ban:     3,
    })

    scope(:user_warned, -> { where.not(warning_type: nil) })
  end

  def user_warned!(type, user)
    update(warning_type: type, warning_user: user, updater: user)
    save_version("mark_#{type}")
  end

  def remove_user_warning!(user)
    update(warning_type: nil, warning_user: nil, updater: user)
    save_version("unmark")
  end

  def was_warned?
    !warning_type.nil?
  end

  def warning_type_string
    case warning_type
    when "warning"
      "User received a warning for the contents of this message"
    when "record"
      "User received a record for the contents of this message"
    when "ban"
      "User was banned for the contents of this message"
    else
      "[This is a bug with the website. Woo!]"
    end
  end
end
