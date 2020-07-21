require "test_helper"

class SuperAdminApplicationEditTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  context "logged in as an superadmin" do
    setup do
      @application = create(:application)

      @superadmin = create(:superadmin_user)
      visit new_user_session_path
      signin_with(@superadmin)
      click_link "Apps"

      # normal user who's authorised to use app
      @user = create(:user)
      ::Doorkeeper::AccessToken.create!(resource_owner_id: @user.id, application_id: @application.id, token: "1234")
    end

    should "be able to enable push updates to applications" do
      @application.update! supports_push_updates: false
      click_link @application.name

      # edit application, enable sso push updates
      assert page.has_unchecked_field?("Send push updates to this app")
      check "Send push updates to this app"
      click_button "Save"

      click_link @application.name
      assert page.has_checked_field?("Send push updates to this app")

      # expect push update
      mock_client = mock(reauth_user: nil)
      SSOPushClient.expects(:new).with(@application).returns(mock_client)

      # trigger a push update for reauth
      remote_logout(@user)
    end

    should "be able to disable push updates to applications" do
      @application.update! supports_push_updates: true
      click_link @application.name

      # edit application, disable sso push updates
      assert page.has_checked_field?("Send push updates to this app")
      uncheck "Send push updates to this app"
      click_button "Save"

      click_link @application.name
      assert page.has_unchecked_field?("Send push updates to this app")

      # don't expect push update
      SSOPushClient.expects(:new).with(@application).never

      # trigger a push update for reauth
      remote_logout(@user)
    end

    should "be able to retire applications" do
      @application.update! retired: false
      click_link @application.name

      assert_not page.has_checked_field?("This application is retired")
      check "This application is retired"
      click_button "Save"

      click_link @application.name

      assert page.has_checked_field?("This application is retired")
      assert @application.reload.retired?, "The record should be retired"
    end
  end

  def remote_logout(user)
    # simulate reauth
    perform_enqueued_jobs do
      ReauthEnforcer.perform_on(user)
    end
  end
end
