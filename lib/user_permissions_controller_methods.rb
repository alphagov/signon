module UserPermissionsControllerMethods
private

  def visible_applications(user)
    if user.api_user?
      applications = ::Doorkeeper::Application.includes(:supported_permissions)
      if current_user.superadmin?
        api_user_authorised_apps = user.authorisations.where(revoked_at: nil).pluck(:application_id)
        applications.where(id: api_user_authorised_apps)
      else
        applications.none
      end
    else
      policy_scope(:user_permission_manageable_application)
    end
  end

  def applications_and_permissions(user)
    zip_permissions(visible_applications(user).includes(:supported_permissions), user)
  end

  def zip_permissions(applications, user)
    applications.map do |application|
      [application, user.application_permissions.where(application_id: application.id)]
    end
  end

  def all_applications_and_permissions_for(user)
    user.supported_permissions.includes(:application).group_by(&:application)
  end
end
