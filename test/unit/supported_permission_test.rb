require 'test_helper'

class SupportedPermissionTest < ActiveSupport::TestCase

  test "name of signin permission cannot be changed" do
    application = create(:application)

    assert_raises ActiveRecord::RecordInvalid do
      application.signin_permission.update_attributes!(name: 'sign-in')
    end
  end

  test "name of permissions other than signin be changed" do
    @permission = create(:supported_permission, name: 'writer')

    assert_nothing_raised do
      @permission.update_attributes!(name: 'write')
    end
  end

end
