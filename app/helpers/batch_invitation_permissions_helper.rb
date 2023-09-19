module BatchInvitationPermissionsHelper
  def formatted_permission_name(application_name, permission_name)
    if permission_name == SupportedPermission::SIGNIN_NAME
      "Has access to #{application_name}?"
    else
      permission_name
    end
  end

  def permissions_for(application)
    all_permissions = application.supported_permissions.grantable_from_ui
    signin, others = all_permissions.partition(&:signin?)

    signin + others.sort_by(&:name)
  end
end
