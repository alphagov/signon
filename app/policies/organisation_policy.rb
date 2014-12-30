class OrganisationPolicy < BasePolicy

  def can_assign?
    current_user.organisation.subtree.pluck(:id).include?(record.id)
  end

  class Scope < Scope
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
