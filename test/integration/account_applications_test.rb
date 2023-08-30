require "test_helper"

class AccountApplicationsTest < ActionDispatch::IntegrationTest
  context "#index" do
    setup do
      @application = create(:application, name: "app-name", description: "app-description")
      @retired_application = create(:application, retired: true, name: "retired-app-name")
      @user = FactoryBot.create(:admin_user)
    end

    should "not be accessible to signed out users" do
      visit account_applications_path

      assert_current_url new_user_session_path
    end

    should "list the applications the user has access to" do
      @user.grant_application_signin_permission(@application)

      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      assert page.has_content?("app-name")
      assert page.has_content?("app-description")
    end

    should "not list retired applications the user has access to" do
      @user.grant_application_signin_permission(@retired_application)

      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      assert_not page.has_content?("retired-app-name")
    end

    should "not list the applications the user does not have access to" do
      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      assert_not page.has_content?("app-name")
    end
  end
end
