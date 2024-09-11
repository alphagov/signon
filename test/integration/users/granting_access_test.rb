require "test_helper"

class Users::GrantingAccessTest < ActionDispatch::IntegrationTest
  def assert_grant_access_to_other_user(application, other_user)
    assert_edit_other_user(other_user)
    assert_grant_access(application, other_user)
  end

  def refute_grant_access_to_other_user(application, other_user)
    assert_edit_other_user(other_user)
    refute_grant_access(application)
  end

  setup do
    @application = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
    @granter = create(:user_in_organisation, with_signin_permissions_for: [@application])
    @grantee = create(:user, organisation: @granter.organisation)
  end

  context "when the signin permission is delegatable, the grantee is in the same organisation, and the granter has access" do
    %w[superadmin admin super_organisation_admin organisation_admin].each do |role|
      context "as a #{role}" do
        setup do
          @granter.update!(role:)
          visit new_user_session_path
          signin_with @granter
        end

        should("be able to grant access") { assert_grant_access_to_other_user(@application, @grantee) }
      end
    end
  end

  context "when the signin permission is not delegatable" do
    setup { @application.signin_permission.update!(delegatable: false) }

    %w[superadmin admin].each do |admin_role|
      context "as a #{admin_role}" do
        setup do
          @granter.update!(role: admin_role)
          visit new_user_session_path
          signin_with @granter
        end

        should("be able to grant access") { assert_grant_access_to_other_user(@application, @grantee) }
      end
    end

    %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
      context "as a #{publishing_manager_role}" do
        setup do
          @granter.update!(role: publishing_manager_role)
          visit new_user_session_path
          signin_with @granter
        end

        should("not be able to grant access") { refute_grant_access_to_other_user(@application, @grantee) }
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

        should("be able to grant access") { assert_grant_access_to_other_user(@application, @grantee) }
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

        should("be able to grant access") { assert_grant_access_to_other_user(@application, @grantee) }
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

        should("be able to grant access") { assert_grant_access_to_other_user(@application, @grantee) }
      end
    end

    %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
      context "as a #{publishing_manager_role}" do
        setup do
          @granter.update!(role: publishing_manager_role)
          visit new_user_session_path
          signin_with @granter
        end

        should("not be able to grant access") { refute_grant_access_to_other_user(@application, @grantee) }
      end
    end
  end
end
