require "doorkeeper/application"

class SetSigninAsDefaultPermissionForAssetManagerAndGrantToAllUsers < ActiveRecord::Migration[5.1]
  def up
    asset_manager_app = Doorkeeper::Application.find_by!(name: "Asset Manager")

    say_with_time "Marking signin on Asset Manager as default permission" do
      asset_manager_app.signin_permission.update(default: true)
    end

    say_with_time "Enqueuing bulk grant permissions job as a super admin to make sure all existing users have the default permissions" do
      superadmin = User.with_status("active").where(role: "superadmin").first
      bulk_grant = BulkGrantPermissionSet.create!(
        user: superadmin,
        supported_permission_ids: [asset_manager_app.signin_permission.id],
      )
      bulk_grant.enqueue
    end
  end

  def down
    # We can't undo the bulk grant because we don't know who had these
    # permissions explicitly before we bulk granted them

    asset_manager_app = Doorkeeper::Application.find_by!(name: "Asset Manager")

    say_with_time "Removing default permission status from signin on Asset Manager" do
      asset_manager_app.signin_permission.update(default: false)
    end
  end
end
