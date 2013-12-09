require 'test_helper'

class SupportedPermissionTest < ActiveSupport::TestCase

  test "name of signin permission cannot be changed" do
    @signin = FactoryGirl.create(:supported_permission, name: 'signin')

    assert_raises ActiveRecord::RecordInvalid do
      @signin.update_attributes!(name: 'sign-in')
    end
  end

  test "name of permissions other than signin be changed" do
    @permission = FactoryGirl.create(:supported_permission, name: 'writer')

    assert_nothing_raised do
      @permission.update_attributes!(name: 'write')
    end
  end

end
