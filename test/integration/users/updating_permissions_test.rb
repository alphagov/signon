require "test_helper"

class Users::UpdatingPermissionsTest < ActionDispatch::IntegrationTest
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

      @granter = create(:user_in_organisation, with_signin_permissions_for: [@application])
      @grantee = create(
        :user,
        organisation: @granter.organisation,
        with_signin_permissions_for: [@application],
        with_permissions: { @application => [
          @old_delegated_grantable_permission,
          @old_non_delegated_grantable_permission,
          @old_delegated_non_grantable_permission,
        ].map(&:name) },
      )
    end

    context "when the grantee is in the same organisation, and the granter has access" do
      %w[superadmin admin super_organisation_admin organisation_admin].each do |role|
        context "as a #{role}" do
          setup do
            @granter.update!(role:)
            visit new_user_session_path
            signin_with @granter
          end

          should "be able to grant delegated non-signin permissions that are grantable from the UI" do
            assert_update_permissions_for_other_user(
              @application, @grantee,
              grant: [@new_delegated_grantable_permission],
              revoke: [@old_delegated_grantable_permission]
            )

            refute_update_permissions_for_other_user(
              @application,
              [@old_delegated_non_grantable_permission, @new_delegated_non_grantable_permission],
              @grantee,
            )
          end
        end
      end

      %w[superadmin admin].each do |admin_role|
        context "as a #{admin_role}" do
          setup do
            @granter.update!(role: admin_role)
            visit new_user_session_path
            signin_with @granter
          end

          should "be able to grant non-delegated permissions" do
            assert_update_permissions_for_other_user(
              @application, @grantee,
              grant: [@new_non_delegated_grantable_permission],
              revoke: [@old_non_delegated_grantable_permission]
            )
          end
        end
      end

      %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
        context "as a #{publishing_manager_role}" do
          setup do
            @granter.update!(role: publishing_manager_role)
            visit new_user_session_path
            signin_with @granter
          end

          should "not be able to grant non-delegated permissions" do
            refute_update_permissions_for_other_user(
              @application,
              [@new_non_delegated_grantable_permission, @old_non_delegated_grantable_permission],
              @grantee,
            )
          end
        end
      end
    end

    context "when the grantee is not in the same organisation" do
      setup { @grantee.update!(organisation: create(:organisation)) }

      %w[superadmin admin].each do |admin_role|
        context "as a #{admin_role}" do
          setup do
            @granter.update!(role: admin_role)
            visit new_user_session_path
            signin_with @granter
          end

          should "be able to grant permissions" do
            assert_update_permissions_for_other_user(
              @application, @grantee,
              grant: [@new_delegated_grantable_permission],
              revoke: [@old_delegated_grantable_permission]
            )
          end
        end
      end

      context "as a super_organisation_admin" do
        setup do
          @granter.update!(role: "super_organisation_admin")
          visit new_user_session_path
          signin_with @granter
        end

        should("not be able to edit the user") { refute_edit_other_user(@grantee) }

        context "but the grantee's organisation is a child of the granter's" do
          setup { @grantee.update!(organisation: create(:organisation, parent: @granter.organisation)) }

          should "be able to grant permissions" do
            assert_update_permissions_for_other_user(
              @application, @grantee,
              grant: [@new_delegated_grantable_permission],
              revoke: [@old_delegated_grantable_permission]
            )
          end
        end
      end

      context "as a organisation_admin" do
        setup do
          @granter.update!(role: "organisation_admin")
          visit new_user_session_path
          signin_with @granter
        end

        should("not be able to edit the user") { refute_edit_other_user(@grantee) }

        context "but the grantee's organisation is a child of the granter's" do
          setup { @grantee.update!(organisation: create(:organisation, parent: @granter.organisation)) }

          should("not be able to edit the user") { refute_edit_other_user(@grantee) }
        end
      end
    end

    context "when the granter does not have access" do
      setup { UserApplicationPermission.find_by(user: @granter, supported_permission: @application.signin_permission).destroy }

      %w[superadmin admin].each do |admin_role|
        context "as a #{admin_role}" do
          setup do
            @granter.update!(role: admin_role)
            visit new_user_session_path
            signin_with @granter
          end

          should "be able to grant permissions" do
            assert_update_permissions_for_other_user(
              @application, @grantee,
              grant: [@new_delegated_grantable_permission],
              revoke: [@old_delegated_grantable_permission]
            )
          end
        end
      end

      %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
        context "as a #{publishing_manager_role}" do
          setup do
            @granter.update!(role: publishing_manager_role)
            visit new_user_session_path
            signin_with @granter
          end

          should "not be able to grant any permissions for the app" do
            refute_update_any_permissions_for_app_for_other_user(@application, @grantee)
          end
        end
      end
    end
  end
end
