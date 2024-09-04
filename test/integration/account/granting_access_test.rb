require "test_helper"

class Account::GrantingAccessTest < ActionDispatch::IntegrationTest
  setup { @application = create(:application) }

  %w[superadmin admin].each do |admin_role|
    context "as a #{admin_role}" do
      setup do
        @user = create(:"#{admin_role}_user")
        visit new_user_session_path
        signin_with @user
      end

      should("be able to grant access") { assert_grant_access_to_self(@application, @user) }
    end
  end

  %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
    context "as a #{publishing_manager_role}" do
      setup do
        @user = create(:"#{publishing_manager_role}_user")
        visit new_user_session_path
        signin_with @user
      end

      should("not be able to grant access") { refute_grant_access_to_self(@application) }
    end
  end
end
