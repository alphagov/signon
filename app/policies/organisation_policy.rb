class OrganisationPolicy < BasePolicy
  def index?
    current_user.govuk_admin?
  end

  def can_assign?
    return true if current_user.govuk_admin?

    false
  end

  def edit?
    current_user.superadmin?
  end

  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.govuk_admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
