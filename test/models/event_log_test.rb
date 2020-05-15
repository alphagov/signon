require "test_helper"
require "ipaddr"

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
    assert_not EventLog.new(event_id: EventLog::TWO_STEP_ENABLED.id).valid?
  end

  test "requires an event_id" do
    assert_not EventLog.new(uid: :uid).valid?
  end

  test "requires a mappable event_id" do
    assert_not EventLog.new(uid: :uid, event_id: 99_999).valid?
  end

  EventLog::EVENTS_REQUIRING_INITIATOR.each do |event|
    test "for #{event.description} event is invalid without the initiator" do
      event_log = EventLog.new(uid: :uid, event_id: event.id)
      assert_not event_log.valid?
      assert_includes event_log.errors.full_messages, "Initiator can't be blank"
    end
  end

  context ".record_email_change" do
    should "record event EMAIL_CHANGED when initiator is an admin" do
      user = create(:user, email: "new@example.com")
      event_log = EventLog.record_email_change(user, "old@example.com", user.email, create(:admin_user))

      assert_equal EventLog::EMAIL_CHANGED, event_log.entry
    end

    should "record event EMAIL_CHANGE_INITIATED when a user is changing their own email" do
      user = create(:user, email: "new@example.com")
      event_log = EventLog.record_email_change(user, "old@example.com", user.email)

      assert_equal EventLog::EMAIL_CHANGE_INITIATED, event_log.entry
    end

    should "record email change events with a trailing message" do
      user = create(:user, email: "new@example.com")
      event_log = EventLog.record_email_change(user, "old@example.com", user.email)

      assert_equal user.uid, event_log.uid
      assert_equal user.id, event_log.initiator_id
      assert_equal "from old@example.com to new@example.com", event_log.trailing_message
    end

    should "record the initiator when initiator is other than the user" do
      user = create(:user, email: "new@example.com")
      admin = create(:admin_user)
      event_log = EventLog.record_email_change(user, "old@example.com", user.email, admin)

      assert_equal admin.id, event_log.initiator_id
    end
  end

  test "records role changes with the details of the roles" do
    user = create(:user, email: "new@example.com")
    admin = create(:admin_user)
    event_log = EventLog.record_role_change(user, "admin", "superadmin", admin)

    assert_equal "from admin to superadmin", event_log.trailing_message
  end

  test "records the initiator of the event passed as an option" do
    initiator = create(:admin_user)
    EventLog.record_event(create(:user), EventLog::EMAIL_CHANGED, initiator: initiator)

    assert_equal initiator, EventLog.last.initiator
  end

  test "records the IPv6 address of the user passed as an option" do
    raw_ip_address = "2001:0db8:0000:0000:0008:0800:200c:417a"
    parsed_ip_address = IPAddr.new(raw_ip_address, Socket::AF_INET6).to_s
    EventLog.record_event(create(:user), EventLog::SUCCESSFUL_LOGIN, ip_address: raw_ip_address)

    assert_equal parsed_ip_address, EventLog.last.ip_address_string
  end

  test "records the IP address of the user passed as an option" do
    raw_ip_address = "1.2.3.4"
    parsed_ip_address = IPAddr.new(raw_ip_address, Socket::AF_INET).to_s
    EventLog.record_event(create(:user), EventLog::SUCCESSFUL_LOGIN, ip_address: raw_ip_address)

    assert_equal parsed_ip_address, EventLog.last.ip_address_string
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
    EventLog.record_event(user, EventLog::PASSWORD_RESET_REQUEST)
    log = user.event_logs.first

    assert_equal log.uid, user.uid
    assert_equal log.entry, EventLog::PASSWORD_RESET_REQUEST
    assert_not_nil log.created_at
  end

  test "can record an account invitation" do
    user = create(:user)
    admin = create(:admin_user)

    event_log = EventLog.record_account_invitation(user, admin)
    assert_equal admin, event_log.initiator
    assert_equal EventLog::ACCOUNT_INVITED, event_log.entry
  end
end
