class SupportedPermissionPolicy < BasePolicy
  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.superadmin?
        scope.all
      elsif current_user.admin?
        scope.all
      elsif current_user.organisation_admin?
        app_ids = Pundit.policy_scope(current_user, :user_permission_manageable_application).pluck(:id)
        scope.joins(:application).where(oauth_applications: { id: app_ids })
      else
        scope.none
      end
    end
  end
end
