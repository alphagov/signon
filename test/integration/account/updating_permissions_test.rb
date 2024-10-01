require "test_helper"

class Account::UpdatingPermissionsTest < ActionDispatch::IntegrationTest
  # See also: UpdatingPermissionsForAppsWithManyPermissionsTest

  context "for all apps" do
    setup do
      @application = create(:application)

      @old_delegated_grantable_permission,
      @new_delegated_grantable_permission = Array.new(2).map do |_|
        create(:delegated_supported_permission, application: @application)
      end

      @old_non_delegated_grantable_permission,
      @new_non_delegated_grantable_permission = Array.new(2).map do |_|
        create(:non_delegated_supported_permission, application: @application)
      end

      @old_delegated_non_grantable_permission,
      @new_delegated_non_grantable_permission = Array.new(2).map do |_|
        create(
          :delegated_supported_permission,
          application: @application,
          grantable_from_ui: false,
        )
      end

      @user = create(
        :user_in_organisation,
        with_signin_permissions_for: [@application],
        with_permissions: { @application => [
          @old_delegated_grantable_permission,
          @old_non_delegated_grantable_permission,
          @old_delegated_non_grantable_permission,
        ].map(&:name) },
      )
    end

    %w[superadmin admin super_organisation_admin organisation_admin].each do |role|
      context "as a #{role}" do
        setup do
          @user.update!(role:)
          visit new_user_session_path
          signin_with @user
        end

        should "be able to grant delegated non-signin permissions that are grantable from the UI" do
          assert_update_permissions_for_self(
            @application, @user,
            grant: [@new_delegated_grantable_permission],
            revoke: [@old_delegated_grantable_permission]
          )

          refute_update_permissions_for_self(@application, [
            @old_delegated_non_grantable_permission,
            @new_delegated_non_grantable_permission,
          ])
        end
      end
    end

    %w[superadmin admin].each do |admin_role|
      context "as a #{admin_role}" do
        setup do
          @user.update!(role: admin_role)
          visit new_user_session_path
          signin_with @user
        end

        should "be able to grant non-delegated permissions" do
          assert_update_permissions_for_self(
            @application, @user,
            grant: [@new_non_delegated_grantable_permission],
            revoke: [@old_non_delegated_grantable_permission]
          )
        end
      end
    end

    %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
      context "as a #{publishing_manager_role}" do
        setup do
          @user.update!(role: publishing_manager_role)
          visit new_user_session_path
          signin_with @user
        end

        should "not be able to grant non-delegated permissions" do
          refute_update_permissions_for_self(@application, [
            @new_non_delegated_grantable_permission,
            @old_non_delegated_grantable_permission,
          ])
        end
      end
    end
  end
end
