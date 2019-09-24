require "test_helper"

class UserApplicationPermissionTest < ActiveSupport::TestCase
  context "validations" do
    setup do
      @user = create(:user)
      @application = create(:application)
      @supported_permission = @application.signin_permission
    end

    should "be invalid without user_id" do
      assert UserApplicationPermission.new(user: nil, supported_permission: @supported_permission).invalid?
    end

    should "be invalid without supported_permission_id" do
      assert UserApplicationPermission.new(supported_permission: nil, user: @user).invalid?
    end

    should "ensure unique user application permissions" do
      application_permission_attributes = { supported_permission: @supported_permission }
      @user.application_permissions.create!(application_permission_attributes)

      assert @user.application_permissions.build(application_permission_attributes).invalid?
    end
  end
end
