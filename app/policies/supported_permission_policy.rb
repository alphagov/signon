class SupportedPermissionPolicy < BasePolicy
  class Scope < ::BasePolicy::Scope
    def resolve
      if current_user.govuk_admin?
        scope.all
      elsif current_user.publishing_manager?
        scope
          .delegatable
          .joins(:application)
          .where(oauth_applications: { id: publishing_manager_manageable_application_ids })
      else
        scope.none
      end
    end

  private

    def publishing_manager_manageable_application_ids
      Doorkeeper::Application
        .not_api_only
        .includes(:supported_permissions)
        .can_signin(current_user)
        .pluck(:id)
    end
  end
end
