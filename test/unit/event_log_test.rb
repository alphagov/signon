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

  EventLog::EVENTS_REQUIRING_INITIATOR.each do |event_name|
    test "for #{event_name} event is invalid without the initiator" do
      event_log = EventLog.new(uid: :uid, event: event_name)
      assert_false event_log.valid?
      assert_include event_log.errors.full_messages, "Initiator can't be blank"
    end
  end

  test "can use a helper to create the eventlog" do
    assert EventLog.record_event(create(:user), :event).valid?
  end

  test "optionally records the initiator of the event" do
    initiator = create(:admin_user)
    EventLog.record_event(create(:user), :event, initiator)

    assert_equal initiator, EventLog.last.initiator
  end

  test "optionally records the application associated with the event" do
    application = create(:application)
    EventLog.record_event(create(:user), :event, nil, application)

    assert_equal application, EventLog.last.application
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
