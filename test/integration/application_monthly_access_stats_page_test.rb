require "test_helper"

class ApplicationMonthlyAccessStatsPageIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @application = create(:application, name: "app-name", description: "app-description")
    @user = create(:user, name: "Normal User")
  end

  test "users don't have permission to view account access log" do
    visit root_path
    signin_with(@user)

    visit monthly_access_stats_doorkeeper_application_path(@application)
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
      visit monthly_access_stats_doorkeeper_application_path(@application)
      assert_equal page.title, "Monthly access counts to app-name - GOV.UK Signon"
    end

    context "when there are no matching events" do
      should "see a message stating that there is no activity logged" do
        visit monthly_access_stats_doorkeeper_application_path(@application)
        assert_text "Monthly access counts to app-name"
        assert_text "No activity logged"
      end
    end

    context "when there are matching events" do
      setup do
        create(:event_log, created_at: Date.new(2020, 1, 1), event_id: 47, application_id: @application.id, uid: @superadmin.uid)
        create(:event_log, created_at: Date.new(2020, 1, 1), event_id: 47, application_id: @application.id, uid: @superadmin.uid)
        create(:event_log, created_at: Date.new(2020, 1, 1), event_id: 47, application_id: @application.id, uid: @user.uid)
        create(:event_log, created_at: Date.new(2020, 2, 1), event_id: 47, application_id: @application.id, uid: @superadmin.uid)
        create(:event_log, created_at: Date.new(2020, 2, 1), event_id: 47, application_id: @application.id, uid: @user.uid)
      end

      should "see a list of events for the application" do
        visit monthly_access_stats_doorkeeper_application_path(@application)
        assert_text "Monthly access counts to #{@application.name}"

        assert_text "Month Total authorization count Unique users authorization count Access logs"
        # Test data has two months - these should be sorted in descending order
        # 2020-02 has two events for two different users, so we should get 2 2
        assert_text "2020-02 2 2 2020-02 access logs"
        # 2020-01 has three events for two different users, so we should get 3 2
        assert_text "2020-01 3 2 2020-01 access logs"
      end
    end
  end

end
