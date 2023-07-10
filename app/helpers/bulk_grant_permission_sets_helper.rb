module BulkGrantPermissionSetsHelper
  def bulk_grant_permission_set_applications
    Pundit.policy_scope(current_user, :user_permission_manageable_application)
      .reject(&:retired?)
  end

  def bulk_grant_permissions_by_application(bulk_grant_permission_set)
    bulk_grant_permission_set
      .supported_permissions
      .includes(:application)
      .order("oauth_applications.name, supported_permissions.name")
      .group_by(&:application)
  end
end
