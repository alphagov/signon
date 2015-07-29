module UserPermissionsControllerMethods
  private

  def visible_applications(user)
    applications = Doorkeeper::Application.includes(:supported_permissions)
    if user.api_user?
      authorised_application_ids = user.authorisations.where(revoked_at: nil).pluck(:application_id)
      visible_applications = applications.where(id: authorised_application_ids)
    elsif current_user.superadmin? || current_user.admin?
      visible_applications = applications
    else
      visible_applications = applications.can_signin(current_user).with_signin_delegatable
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
end
