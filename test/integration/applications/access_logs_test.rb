require "test_helper"

class ApplicationsAccessLogsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @application = create(:application, name: "app-name", description: "app-description")
    @user = create(:user, name: "Normal User")
  end

  test "users don't have permission to view account access log" do
    visit root_path
    signin_with(@user)

    visit access_logs_doorkeeper_application_path(@application)
    flash = find("div[role='alert']")
    assert flash.has_content?("You do not have permission to perform this action.")
  end

  context "logged in as an superadmin" do
    setup do
      visit new_user_session_path
      @superadmin = create(:superadmin_user)
      signin_with(@superadmin)
    end

    should "have permission to view account access log" do
      visit access_logs_doorkeeper_application_path(@application)
      assert_equal page.title, "app-name access log - GOV.UK Signon"
    end

    context "when there are no matching events" do
      should "see a message stating that there is no activity logged" do
        visit access_logs_doorkeeper_application_path(@application)
        assert_text "app-name access log"
        assert_text "No activity logged"
      end
    end

    context "when there are matching events" do
      setup do
        event_id = 47
        create(:event_log, event_id:, application_id: @application.id, uid: @superadmin.uid)
        create(:event_log, event_id:, application_id: @application.id, uid: @user.uid)
      end

      should "see a list of events for the application" do
        visit access_logs_doorkeeper_application_path(@application)
        assert_text "#{@application.name} access log"
        assert_text "Successful user application authorization for #{@application.name} for #{@superadmin.name}"
        assert_text "Successful user application authorization for #{@application.name} for #{@user.name}"
      end
    end
  end
end
