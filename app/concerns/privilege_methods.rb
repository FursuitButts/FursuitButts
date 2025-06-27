# frozen_string_literal: true

module PrivilegeMethods
  extend(ActiveSupport::Concern)

  module ClassMethods
    def visible(user)
      policy(user).visible_for_search(all)
    end

    def policy(current_user)
      Pundit.policy(current_user, self) || begin
        TraceLogger.warn("No pundit policy found for #{self}", ignore: %r{/concerns/privilege_methods\.rb})
        ApplicationPolicy.new(current_user, self)
      end
    end
  end

  def policy(current_user)
    Pundit.policy(current_user, self) || begin
      TraceLogger.warn("No pundit policy found for #{self.class}", ignore: %r{/concerns/privilege_methods\.rb})
      ApplicationPolicy.new(current_user, self)
    end
  end
end
