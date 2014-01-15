class SigninPermissionsMustBeLowercase < ActiveRecord::Migration
  def up
    SupportedPermission.update_all({ name: 'signin' }, { name: 'Signin' })
  end
end
