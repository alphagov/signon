class RemoveUserApplicationPermissionsWithDeletedSupportedPermission < ActiveRecord::Migration[7.1]
  def change
    return unless SupportedPermission.find_by(id: 2316).nil?

    user_application_permissions_to_destroy = UserApplicationPermission.where(supported_permission_id: 2316)
    initiator = User.find_by(email: "ynda.jas@digital.cabinet-office.gov.uk")

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
          trailing_message: "(previously deleted permission with ID 2316 removed via migration)",
        )
      end
    end
  end
end
