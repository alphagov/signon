require "test_helper"

class ExpiredNotSignedInUserDeleterTest < ActiveSupport::TestCase
  test "deletes web users who've never signed in and were invited over 90 days ago" do
    create(:user).tap(&:invite!)
    has_signed_in = create(:user, current_sign_in_at: 1.day.ago).tap(&:invite!)

    Timecop.travel(91.days)

    more_recently_invited = create(:user).tap(&:invite!)

    ExpiredNotSignedInUserDeleter.new.delete

    assert_equal [has_signed_in, more_recently_invited], User.all
  end

  test "creates an activity log entry for each deleted user" do
    user = create(:user, email: "landon.leonardsson@dept.gov.uk").tap(&:invite!)

    Timecop.travel(91.days)

    ExpiredNotSignedInUserDeleter.new.delete

    event_logs = user.event_logs(event: EventLog::ACCOUNT_DELETED)
    assert_equal(1, event_logs.count)
    assert_match(/landon\.leonardsson@dept\.gov\.uk.*never signed in/,
                 event_logs.first.trailing_message)
  end

  test "doesn't delete users who've been re-invited within the past 90 days" do
    user = create(:user).tap(&:invite!)

    Timecop.travel(91.days)

    user.invite!

    ExpiredNotSignedInUserDeleter.new.delete

    assert_equal [user], User.all
  end

  test "doesn't delete API users" do
    api_user = create(:api_user).tap(&:invite!)

    Timecop.travel(91.days)

    ExpiredNotSignedInUserDeleter.new.delete

    assert_equal [api_user], ApiUser.all
  end
end
