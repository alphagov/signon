require "test_helper"

class SuspensionTest < ActiveSupport::TestCase
  setup do
    EventLog.stubs(:record_event)
    PermissionUpdater.stubs(:perform_on)
    ReauthEnforcer.stubs(:perform_on)
  end

  should "be valid when a reason is given for a suspension" do
    suspension = Suspension.new(suspend: true, reason_for_suspension: "A reason")

    assert suspension.valid?
  end

  should "be valid when no reason is given for an unsuspension" do
    suspension = Suspension.new(suspend: false)

    assert suspension.valid?
  end

  should "be invalid when no reason is given for a suspension" do
    suspension = Suspension.new(suspend: true)

    assert_not suspension.valid?
  end

  should "not save an invalid suspension" do
    suspension = Suspension.new(suspend: true)

    assert_not suspension.valid?
    assert_not suspension.save
  end

  should "suspend a user when suspend is true and a reason is given" do
    user = mock
    user.expects(:suspend).with("A reason")

    suspension = Suspension.new(suspend: true, reason_for_suspension: "A reason", user:)

    suspension.save!
  end

  should "unsuspend a user when suspend is false" do
    user = mock
    user.expects(:unsuspend)

    suspension = Suspension.new(suspend: false, user:)

    suspension.save!
  end

  should "log unsuspend events" do
    user = stub(unsuspend: true)

    EventLog.expects(:record_event).with(user, EventLog::ACCOUNT_UNSUSPENDED, initiator: true, ip_address: true)
    suspension = Suspension.new(suspend: false, user:)

    suspension.save!
  end

  should "log suspend events" do
    user = stub(suspend: true)

    EventLog.expects(:record_event).with(user, EventLog::ACCOUNT_SUSPENDED, initiator: true, ip_address: true)
    suspension = Suspension.new(suspend: true, reason_for_suspension: "A reason", user:)

    suspension.save!
  end

  should "call the PermissionUpdater when saving" do
    user = stub(unsuspend: true)

    PermissionUpdater.expects(:perform_on).with(user)
    suspension = Suspension.new(suspend: false, user:)

    suspension.save!
  end

  should "call the ReauthEnforcer when saving" do
    user = stub(unsuspend: true)

    ReauthEnforcer.expects(:perform_on).with(user)
    suspension = Suspension.new(suspend: false, user:)

    suspension.save!
  end

  should "be suspended when suspend is true" do
    assert Suspension.new(suspend: true).suspended?
    assert_not Suspension.new(suspend: false).suspended?
  end
end
