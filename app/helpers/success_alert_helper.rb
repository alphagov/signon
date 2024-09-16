module SuccessAlertHelper
  def access_and_permissions_granted_params(application_id, granting_access:, user: current_user)
    if granting_access
      {
        message: "Access granted",
        description: access_granted_message(application_id, user),
      }
    else
      {
        message: "Permissions updated",
        description: message_for_success(application_id, user),
      }
    end
  end

  def access_removed_params(application_id, user: current_user)
    {
      message: "Access removed",
      description: access_removed_message(application_id, user),
    }
  end
end
