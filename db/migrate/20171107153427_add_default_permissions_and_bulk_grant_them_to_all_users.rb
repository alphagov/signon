require 'enhancements/application'

class AddDefaultPermissionsAndBulkGrantThemToAllUsers < ActiveRecord::Migration
  def up
    support_app = Doorkeeper::Application.find_by!(name: 'Support')
    content_preview_app = Doorkeeper::Application.find_by!(name: 'Content Preview')

    say_with_time 'Marking signin on support and content preview as default permissions' do
      support_app.signin_permission.update_attributes(default: true)

      content_preview_app.signin_permission.update_attributes(default: true)
    end

    say_with_time 'Enqueuing bulk grant permissions job as a super admin to make sure all existing users have the default permissions' do
      superadmin = User.with_status('active').where(role: 'superadmin').first
      bulk_grant = BulkGrantPermissionSet.create!(
        user: superadmin,
        supported_permission_ids: [support_app.signin_permission.id, content_preview_app.signin_permission.id]
      )
      bulk_grant.enqueue
    end
  end

  def down
    # We can't undo the bulk grant because we don't know who had these
    # permissions explicitly before we bulk granted them

    say_with_time 'Removing default permission status from signin on support and content preview' do
      content_preview_app = Doorkeeper::Application.find_by(name: 'Content Preview')
      content_preview_app.signin_permission.update_attributes(default: false)

      support_app = Doorkeeper::Application.find_by(name: 'Support')
      support_app.signin_permission.update_attributes(default: false)
    end
  end
end
