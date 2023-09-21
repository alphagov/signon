module PermissionsHelper
  def permissions_for(application)
    all_permissions = application.supported_permissions.grantable_from_ui
    signin, others = all_permissions.partition(&:signin?)

    signin + others.sort_by(&:name)
  end
end
