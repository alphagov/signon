namespace :permissions_promoter do
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
end
