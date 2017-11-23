class SigninPermissionsMustBeLowercase < ActiveRecord::Migration[4.2]
  def up
    SupportedPermission.where(name: 'Signin')
                       .update_all(name: 'signin')
  end
end
