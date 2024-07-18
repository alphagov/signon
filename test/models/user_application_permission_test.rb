require "test_helper"

class UserApplicationPermissionTest < ActiveSupport::TestCase
  context ".for" do
    setup do
      @user = build(:user)
      @supported_permission = build(:supported_permission)
      @application = build(:application, supported_permissions: [@supported_permission])
    end

    context "for a user, supported permission, and application" do
      setup { @result = UserApplicationPermission.for(user: @user, supported_permission: @supported_permission, application: @application) }

      should "return a UserApplicationPermission with the given associations" do
        assert @result.instance_of?(UserApplicationPermission)
        assert_equal @user, @result.user
        assert_equal @supported_permission, @result.supported_permission
        assert_equal @application, @result.application
      end

      should "not persist the UserApplicationPermission" do
        assert_not @result.persisted?
      end
    end

    context "without an application" do
      should "infer the application from the supported permission" do
        result = UserApplicationPermission.for(user: @user, supported_permission: @supported_permission)

        assert_equal @application, result.application
      end
    end
  end

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
