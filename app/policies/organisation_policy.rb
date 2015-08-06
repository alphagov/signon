class OrganisationPolicy < BasePolicy
  def index?
    current_user.superadmin? || current_user.admin? || current_user.organisation_admin?
  end

  def can_assign?
    return true if current_user.superadmin? || current_user.admin?
    return current_user.organisation.subtree.pluck(:id).include?(record.id) if current_user.organisation_admin?

    false
  end

  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.organisation_admin?
        current_user.organisation.subtree
      elsif current_user.admin? || current_user.superadmin?
        scope.all
      else
        []
      end
    end
  end
end
