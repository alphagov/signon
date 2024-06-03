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
    user_editor_permissions_to_destroy_ids = UserApplicationPermission.where(
      supported_permission: whitehall_editor_permission,
      user_id: non_gds_users_with_managing_editor_permission_user_ids,
    )

    user_editor_permissions_to_destroy_ids.destroy_all
  end
end
