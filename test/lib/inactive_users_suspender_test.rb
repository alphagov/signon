require "test_helper"

class InactiveUsersSuspenderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "suspends users who have not logged-in for more than suspension threshold days" do
    inactive_user = create(:user, current_sign_in_at: 46.days.ago)

    InactiveUsersSuspender.new.suspend

    assert inactive_user.reload.suspended?
  end

  test "suspension reason contains suspension threshold date" do
    inactive_user = create(:user, current_sign_in_at: 46.days.ago)

    InactiveUsersSuspender.new.suspend

    assert_equal "User has not logged in for 45 days since #{46.days.ago.strftime('%d %B %Y')}", inactive_user.reload.reason_for_suspension
  end

  test "doesn't suspend users who have logged-in suspension threshold days ago" do
    active_user = create(:user, current_sign_in_at: 45.days.ago)

    InactiveUsersSuspender.new.suspend

    assert_not active_user.reload.suspended?
  end

  test "doesn't suspend users who have logged-in since suspension threshold days ago" do
    active_user = create(:user, current_sign_in_at: 44.days.ago)

    InactiveUsersSuspender.new.suspend

    assert_not active_user.reload.suspended?
  end

  test "doesn't suspend users who have recently been unsuspended" do
    create(:admin_user)
    unsuspended_user = create(:suspended_user, current_sign_in_at: 46.days.ago)
    Timecop.travel(2.days.ago) do
      unsuspended_user.unsuspend
    end

    InactiveUsersSuspender.new.suspend

    assert_not unsuspended_user.reload.suspended?
  end

  test "doesn't modify users who are suspended" do
    suspended_user = create(:user, suspended_at: Time.zone.today, reason_for_suspension: "traitor")

    InactiveUsersSuspender.new.suspend

    assert suspended_user.reload.suspended?
  end

  test "returns the count of users who got suspended" do
    create_list(:user, 2, current_sign_in_at: 46.days.ago)

    assert_equal 2, InactiveUsersSuspender.new.suspend
  end

  test "records auto-suspension in event log" do
    users = create_list(:user, 2, current_sign_in_at: 46.days.ago)
    users.each do |user|
      EventLog.expects(:record_event)
        .with(responds_with(:email, user.email), EventLog::ACCOUNT_AUTOSUSPENDED)
        .once
    end

    InactiveUsersSuspender.new.suspend
  end

  test "sends suspension notification to users who got suspended" do
    users = create_list(:user, 2, current_sign_in_at: 46.days.ago)

    mailer = mock
    mailer.expects(:deliver_now).returns(true).twice
    users.each do |user|
      UserMailer.expects(:suspension_notification)
        .with(responds_with(:email, user.email))
        .returns(mailer).once
    end

    InactiveUsersSuspender.new.suspend
  end

  test "syncs permissions with downstream apps to inform them about suspension" do
    inactive_user = create(:user, current_sign_in_at: 46.days.ago)
    PermissionUpdater.expects(:perform_on).with(inactive_user)

    InactiveUsersSuspender.new.suspend
  end

  test "enforces downstream apps to log-off the suspended user" do
    inactive_user = create(:user, current_sign_in_at: 46.days.ago)
    ReauthEnforcer.expects(:perform_on).with(inactive_user)

    InactiveUsersSuspender.new.suspend
  end
end
