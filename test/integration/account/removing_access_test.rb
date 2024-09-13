require "test_helper"

class Account::RemovingAccessTest < ActionDispatch::IntegrationTest
  setup do
    @application = create(:application)
    @user = create(:user_in_organisation, with_signin_permissions_for: [@application])
  end

  context "when the signin permission is delegatable" do
    setup { @application.signin_permission.update!(delegatable: true) }

    %w[superadmin admin super_organisation_admin organisation_admin].each do |role|
      context "as a #{role}" do
        setup do
          @user.update!(role:)
          visit new_user_session_path
          signin_with @user
        end

        should "be able to remove their own access to the application" do
          visit account_applications_path

          click_link "Remove access to #{@application.name}"
          click_button "Confirm"

          apps_without_access_table = find("table caption[text()='Apps you don\\'t have access to']").ancestor("table")

          assert apps_without_access_table.has_content?(@application.name)
          assert_not @user.has_access_to?(@application)
        end
      end
    end
  end

  context "when the signin permission is not delegatable" do
    setup { @application.signin_permission.update!(delegatable: false) }

    %w[superadmin admin].each do |admin_role|
      context "as a #{admin_role}" do
        setup do
          @user.update!(role: admin_role)
          visit new_user_session_path
          signin_with @user
        end

        should "be able to remove their own access to the application" do
          visit account_applications_path

          click_link "Remove access to #{@application.name}"
          click_button "Confirm"

          apps_without_access_table = find("table caption[text()='Apps you don\\'t have access to']").ancestor("table")

          assert apps_without_access_table.has_content?(@application.name)
          assert_not @user.has_access_to?(@application)
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

        should "not be able to remove their own access to the application" do
          visit account_applications_path
          assert page.has_content?("GOV.UK apps")

          assert_not page.has_link?("Remove access to #{@application.name}")
        end
      end
    end
  end
end
