require 'test_helper'

class EventLogTest < ActiveSupport::TestCase
  context "#event" do
    context "when the event has an `event_id`" do
      should "return the correctly mapped event description" do
        assert_equal "Account suspended", EventLog.new(event_id: EventLog::ACCOUNT_SUSPENDED.id).event
      end
    end
  end

  test "can create a valid eventlog" do
    assert EventLog.new(uid: :uid, event_id: EventLog::TWO_STEP_ENABLED.id).valid?
  end

  test "requires a user uid" do
    refute EventLog.new(event_id: EventLog::TWO_STEP_ENABLED.id).valid?
  end

  test "requires an event_id" do
    refute EventLog.new(uid: :uid).valid?
  end

  test "requires a mappable event_id" do
    refute EventLog.new(uid: :uid, event_id: 99999).valid?
  end

  EventLog::EVENTS_REQUIRING_INITIATOR.each do |event|
    test "for #{event.description} event is invalid without the initiator" do
      event_log = EventLog.new(uid: :uid, event_id: event.id)
      refute event_log.valid?
      assert_includes event_log.errors.full_messages, "Initiator can't be blank"
    end
  end

  context ".record_email_change" do
    should "record event EMAIL_CHANGED when initiator is an admin" do
      user = create(:user, email: 'new@example.com')
      event_log = EventLog.record_email_change(user, 'old@example.com', user.email, create(:admin_user))

      assert_equal EventLog::EMAIL_CHANGED, event_log.entry
    end

    should "record event EMAIL_CHANGE_INITIATED when a user is changing their own email" do
      user = create(:user, email: 'new@example.com')
      event_log = EventLog.record_email_change(user, 'old@example.com', user.email)

      assert_equal EventLog::EMAIL_CHANGE_INITIATED, event_log.entry
    end

    should "record email change events with a trailing message" do
      user = create(:user, email: 'new@example.com')
      event_log = EventLog.record_email_change(user, 'old@example.com', user.email)

      assert_equal user.uid, event_log.uid
      assert_equal user.id, event_log.initiator_id
      assert_equal 'from old@example.com to new@example.com', event_log.trailing_message
    end

    should "record the initiator when initiator is other than the user" do
      user = create(:user, email: 'new@example.com')
      admin = create(:admin_user)
      event_log = EventLog.record_email_change(user, 'old@example.com', user.email, admin)

      assert_equal admin.id, event_log.initiator_id
    end
  end

  test "records the initiator of the event passed as an option" do
    initiator = create(:admin_user)
    EventLog.record_event(create(:user), EventLog::EMAIL_CHANGED, initiator: initiator)

    assert_equal initiator, EventLog.last.initiator
  end

  test "records the application associated with the event passed as an option" do
    application = create(:application)
    EventLog.record_event(create(:user), EventLog::ACCESS_TOKEN_REGENERATED, application: application)

    assert_equal application, EventLog.last.application
  end

  test "skips invalid options passed" do
    user = create(:user)
    EventLog.record_event(user, EventLog::TWO_STEP_CHANGED, uid: build(:user).uid)

    assert_equal user.uid, EventLog.last.uid
  end

  test "can use a helper to fetch all logs for a user" do
    user = create(:user)
    EventLog.record_event(user, EventLog::PASSPHRASE_RESET_REQUEST)
    log = user.event_logs.first

    assert_equal log.uid, user.uid
    assert_equal log.entry, EventLog::PASSPHRASE_RESET_REQUEST
    assert_not_nil log.created_at
  end
end
