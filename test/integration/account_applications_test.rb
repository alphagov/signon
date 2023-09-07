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

      table = find("table caption[text()='Apps you have access to']").ancestor("table")
      assert table.has_content?("app-name")
      assert table.has_content?("app-description")
    end

    should "not list retired applications the user has access to" do
      @user.grant_application_signin_permission(@retired_application)

      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      assert_not page.has_content?("retired-app-name")
    end

    should "list the applications the user does not have access to" do
      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      heading = find("h2", text: "Apps you don't have access to")
      table = find("table[aria-labelledby='#{heading['id']}']")

      assert table.has_content?("app-name")
      assert table.has_content?("app-description")
    end

    should "not list retired applications the user does not have access to" do
      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      assert_not page.has_content?("retired-app-name")
    end
  end

  context "granting access to apps" do
    setup do
      create(:application, name: "app-name", description: "app-description")
      @user = create(:admin_user)
    end

    should "allow admins to grant themselves access to apps" do
      visit new_user_session_path
      signin_with @user

      visit account_applications_path

      click_on "Grant access to app-name"

      table = find("table caption[text()='Apps you have access to']").ancestor("table")
      assert table.has_content?("app-name")
    end
  end
end
