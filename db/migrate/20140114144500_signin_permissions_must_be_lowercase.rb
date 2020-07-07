class SigninPermissionsMustBeLowercase < ActiveRecord::Migration[3.2]
  def up
    SupportedPermission.where(name: "Signin")
                       .update_all(name: "signin")
  end
end
