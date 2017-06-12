class OrganisationPolicy < BasePolicy
  def index?
    current_user.superadmin? || current_user.admin?
  end

  def can_assign?
    return true if current_user.superadmin? || current_user.admin?

    false
  end

  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.admin? || current_user.superadmin?
        scope.all
      else
        scope.none
      end
    end
  end
end
