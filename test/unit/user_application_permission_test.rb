require 'test_helper'

class UserApplicationPermissionTest < ActiveSupport::TestCase

  test "uniqueness of user's application permissions" do
    user, application = create(:user), create(:application)
    supported_permission = application.signin_permission

    application_permission_attributes = { application: application, supported_permission: supported_permission }
    user.application_permissions.create!(application_permission_attributes)

    assert user.application_permissions.build(application_permission_attributes).invalid?
  end

end
