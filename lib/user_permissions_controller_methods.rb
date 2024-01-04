module UserPermissionsControllerMethods
private

  def applications_and_permissions(user)
    zip_permissions(policy_scope(:user_permission_manageable_application).includes(:supported_permissions), user)
  end

  def zip_permissions(applications, user)
    applications.map do |application|
      [application, user.application_permissions.where(application_id: application.id)]
    end
  end
end
