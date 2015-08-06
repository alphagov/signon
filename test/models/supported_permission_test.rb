require 'test_helper'

class SupportedPermissionTest < ActiveSupport::TestCase
  test "name of signin permission cannot be changed" do
    application = create(:application)

    assert_raises ActiveRecord::RecordInvalid do
      application.signin_permission.update_attributes!(name: 'sign-in')
    end
  end

  test "name of permissions other than signin be changed" do
    permission = create(:supported_permission, name: 'writer')

    assert_nothing_raised do
      permission.update_attributes!(name: 'write')
    end
  end

  test "associated user application permissions are destroyed when supported permissions are destroyed" do
    user = create(:user)
    application = create(:application, with_supported_permissions: ['managing_editor'])
    managing_editor_permission = application.supported_permissions.where(name: 'managing_editor').first

    user.grant_application_permission(application, 'managing_editor')
    managing_editor_permission.destroy

    assert_empty user.reload.application_permissions
  end
end
