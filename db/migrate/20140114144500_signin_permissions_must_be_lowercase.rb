class SigninPermissionsMustBeLowercase < ActiveRecord::Migration[6.0]
  def up
    SupportedPermission.where(name: "Signin")
                       .update_all(name: "signin")
  end
end
