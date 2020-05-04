module BulkGrantPermissionSetsHelper
  def bulk_grant_permission_set_status_message(bulk_grant_permission_set)
    if bulk_grant_permission_set.in_progress?
      "In progress. #{bulk_grant_permission_set.processed_users} of #{bulk_grant_permission_set.total_users} users processed."
    elsif bulk_grant_permission_set.successful?
      "All #{bulk_grant_permission_set.processed_users} users processed."
    else
      "Only #{bulk_grant_permission_set.processed_users} of #{bulk_grant_permission_set.total_users} users processed."
    end
  end

  def bulk_grant_permission_set_status_class(bulk_grant_permission_set)
    if bulk_grant_permission_set.in_progress?
      "alert-info"
    elsif bulk_grant_permission_set.successful?
      "alert-success"
    else
      "alert-danger"
    end
  end

  def bulk_grant_permissions_by_application(bulk_grant_permission_set)
    bulk_grant_permission_set
      .supported_permissions
      .includes(:application)
      .order("oauth_applications.name, supported_permissions.name")
      .group_by(&:application)
  end
end
