require 'test_helper'

class EventLogTest < ActiveSupport::TestCase
  test "can create a valid eventlog" do
    assert EventLog.new(uid: :uid, event: :event).valid?
  end

  test "requires a user uid" do
    assert_false EventLog.new(event: :event).valid?
  end

  test "requires an event" do
    assert_false EventLog.new(uid: :uid).valid?
  end

  test "can use a helper to create the eventlog" do
    assert EventLog.record_event(create(:user), :event).valid?
  end

  test "can use a helper to fetch all logs for a user" do
    user = create(:user)
    EventLog.record_event(user, EventLog::PASSPHRASE_RESET_REQUEST)
    log = EventLog.for(user).first

    assert_equal log.uid, user.uid
    assert_equal log.event, EventLog::PASSPHRASE_RESET_REQUEST
    assert_not_nil log.created_at
  end
end
