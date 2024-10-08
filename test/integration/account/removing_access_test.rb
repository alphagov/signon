require "test_helper"

class Account::RemovingAccessTest < ActionDispatch::IntegrationTest
  setup do
    @application = create(:application)
    @user = create(:user_in_organisation, with_signin_permissions_for: [@application])
  end

  context "when the signin permission is delegated" do
    setup { @application.signin_permission.update!(delegated: true) }

    %w[superadmin admin super_organisation_admin organisation_admin].each do |role|
      context "as a #{role}" do
        setup do
          @user.update!(role:)
          visit new_user_session_path
          signin_with @user
        end

        should("be able to remove access") { assert_remove_access_from_self(@application, @user) }
      end
    end
  end

  context "when the signin permission is not delegated" do
    setup { @application.signin_permission.update!(delegated: false) }

    %w[superadmin admin].each do |admin_role|
      context "as a #{admin_role}" do
        setup do
          @user.update!(role: admin_role)
          visit new_user_session_path
          signin_with @user
        end

        should("be able to remove access") { assert_remove_access_from_self(@application, @user) }
      end
    end

    %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
      context "as a #{publishing_manager_role}" do
        setup do
          @user.update!(role: publishing_manager_role)
          visit new_user_session_path
          signin_with @user
        end

        should("not be able to remove access") { refute_remove_access_from_self(@application) }
      end
    end
  end
end
