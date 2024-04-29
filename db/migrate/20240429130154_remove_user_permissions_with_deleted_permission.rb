class RemoveUserPermissionsWithDeletedPermission < ActiveRecord::Migration[7.1]
  def change
    undeleted_permission = 1152
    return unless SupportedPermission.find_by(id: undeleted_permission).nil?

    user_application_permissions_to_destroy = UserApplicationPermission.where(supported_permission_id: undeleted_permission)
    initiator = User.find_by(email: "callum.knights@digital.cabinet-office.gov.uk")

    ActiveRecord::Base.transaction do
      user_application_permissions_to_destroy.each do |user_application_permission|
        user = user_application_permission.user
        application_id = user_application_permission.application_id

        raise "Could not destroy UserApplicationPermission with ID #{user_application_permission.id}" unless user_application_permission.destroy

        next unless user

        EventLog.record_event(
          user,
          EventLog::PERMISSIONS_REMOVED,
          initiator:,
          application_id:,
          trailing_message: "(previously deleted permission with ID #{undeleted_permission} removed via migration)",
        )
      end
    end
  end
end
