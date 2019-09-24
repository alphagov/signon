class SigninPermissionsMustBeLowercase < ActiveRecord::Migration
  def up
    SupportedPermission.where(name: "Signin")
                       .update_all(name: "signin")
  end
end
