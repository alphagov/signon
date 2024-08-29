namespace :permissions do
  desc "Update anyone with a managing editor permission and a normal role to an org admin role"
  task promote_managing_editors_to_org_admins: :environment do
    managing_editor_permissions = SupportedPermission.where("name REGEXP ?", "managing.*editor").pluck(:id)
    user_application_permissions = UserApplicationPermission.where(supported_permission_id: managing_editor_permissions)
    gds = Organisation.find_by(name: "Government Digital Service")
    users_to_update = user_application_permissions
                        .map { |user_application_permission| User.find(user_application_permission.user_id) }.uniq
                        .filter { |user| user.normal? && !user.suspended? && user.organisation != gds }

    puts "found #{users_to_update.size} users with managing editor positions to be updated to organisation admins"
    puts "user ids to update are #{users_to_update.map(&:id)}"

    users_to_update.each do |user|
      user.update(role: Roles::OrganisationAdmin.name)
    end
  end

  desc "Remove the 'Editor' permission from users in Whitehall with the 'Managing Editor' permission"
  task remove_editor_permission_from_whitehall_managing_editors: :environment do
    gds = Organisation.find_by(name: "Government Digital Service")
    whitehall = Doorkeeper::Application.find_by(name: "Whitehall")
    whitehall_managing_editor_permission = SupportedPermission.find_by(application: whitehall, name: "Managing Editor")
    whitehall_editor_permission = SupportedPermission.find_by(application: whitehall, name: "Editor")

    non_gds_users_with_managing_editor_permission_user_ids = UserApplicationPermission.where(
      supported_permission: whitehall_managing_editor_permission,
      user_id: User.where.not(organisation_id: gds.id),
    ).pluck(:user_id)
    editor_permissions_to_destroy = UserApplicationPermission.where(
      supported_permission: whitehall_editor_permission,
      user_id: non_gds_users_with_managing_editor_permission_user_ids,
    )

    puts "Number of non-GDS users with both managing editor and editor permissions in Whitehall"
    puts "Before removing permissions: #{editor_permissions_to_destroy.count}"

    editor_permissions_to_destroy.destroy_all

    count_of_remaining_users_with_both_permissions = UserApplicationPermission.where(
      supported_permission: whitehall_editor_permission,
      user_id: non_gds_users_with_managing_editor_permission_user_ids,
    ).count

    puts "After removing permissions: #{count_of_remaining_users_with_both_permissions}"
  end

  desc "Get permissions by non-GDS user, and who gave them the permission if we have the data"
  task permissions_by_non_gds_user_and_origin: :environment do
    CSV.open("tmp/permissions_by_non_gds_user.csv", "w") do |csv|
      csv << [
        "Grantee ID",
        "Grantee email",
        "Grantee organisation (now)",
        "Grantee role (now)",
        "Grantee status (now)",
        "Grantee created at",
        "Application",
        "Permission",
        "Permission created at",
        "Permission updated at",
        "Granter ID",
        "Granter email",
        "Granter organisation (now)",
        "Granter role (now)",
        "Event log created at",
        "All permissions added during event",
        "Event log ID",
      ]

      gds_organisation_id = Organisation.find_by(content_id: Organisation::GDS_ORG_CONTENT_ID).id

      User.where.not(organisation_id: gds_organisation_id).find_each do |user|
        event_logs = EventLog
          .where(event_id: EventLog::PERMISSIONS_ADDED.id, uid: user.uid)
          .includes(:initiator)
          .order(created_at: :desc)
          .map do |model_instance|
            {
              model_instance:,
              application_id: model_instance.application&.id,
              permission_names: model_instance.trailing_message[1..-2].split(", "),
            }
          end

        user.application_permissions.find_each do |user_application_permission|
          permission_name = user_application_permission.supported_permission.name
          event_log = event_logs.find do |log|
            next unless log[:application_id] == user_application_permission.application_id

            log[:permission_names].include?(permission_name)
          end
          event_log_cells = if event_log
                              [
                                event_log[:model_instance].initiator_id,
                                event_log[:model_instance].initiator.email,
                                "\"#{event_log[:model_instance].initiator.organisation_name}\"",
                                event_log[:model_instance].initiator.role_name,
                                event_log[:model_instance].created_at,
                                event_log[:model_instance].trailing_message[1..-2].gsub(",", ";"),
                                event_log[:model_instance].id,
                              ]
                            else
                              Array.new(7)
                            end

          csv << [
            user.id,
            user.email,
            "\"#{user.organisation_name}\"",
            user.role_name,
            user.status,
            user.created_at,
            user_application_permission.application.name,
            permission_name,
            user_application_permission.created_at,
            user_application_permission.updated_at,
            *event_log_cells,
          ]
        end
      end
    end
  end
end
