class SystemInfoPolicy < ApplicationPolicy
  def show?
    user.is_owner?
  end
end
