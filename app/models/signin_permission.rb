class SigninPermission
  attr_reader :user_application_permission

  def initialize(user_application_permission)
    @user_application_permission = user_application_permission
  end
end
