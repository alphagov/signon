require 'test_helper'

class InactiveUsersSuspenderTest < ActiveSupport::TestCase

  test "suspends users who have not logged in for more than suspension threshold days" do
    inactive_user = create(:user, current_sign_in_at: 46.days.ago)

    InactiveUsersSuspender.new.suspend

    assert_true inactive_user.reload.suspended?
  end

  test "suspension reason contains suspension threshold date" do
    inactive_user = create(:user, current_sign_in_at: 46.days.ago)

    InactiveUsersSuspender.new.suspend

    assert_equal "User has not logged in for 45 days since #{(46.days.ago).strftime('%d/%m/%Y')}", inactive_user.reload.reason_for_suspension
  end

  test "doesn't suspend users who have logged suspension threshold days back" do
    active_user = create(:user, current_sign_in_at: 45.days.ago)

    InactiveUsersSuspender.new.suspend

    assert_false active_user.reload.suspended?
  end

  test "doesn't suspend users who have logged in since suspension threshold days back" do
    active_user = create(:user, current_sign_in_at: 44.days.ago)

    InactiveUsersSuspender.new.suspend

    assert_false active_user.reload.suspended?
  end

  test "doesn't modify users who are suspended" do
    suspended_user = create(:user, suspended_at: Date.today, reason_for_suspension: 'traitor')

    InactiveUsersSuspender.new.suspend

    assert_true suspended_user.reload.suspended?
  end

end
