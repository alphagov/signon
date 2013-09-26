class RemoveSupportAppErtpPermission < ActiveRecord::Migration
  def up
    support = ::Doorkeeper::Application.find_by_name("Support")

    permission = SupportedPermission.find_by_application_id_and_name(support.id, "ertp")
    permission.delete

    # remove user permissions
    all_support_perms = Permission.where(application_id: support.id)
    ertp_support_perms = all_support_perms.select { |perm| perm.permissions.include?("ertp") }
    ertp_support_perms.each { |perm| perm.permissions -= ["ertp"]; perm.save! }
  end
end
