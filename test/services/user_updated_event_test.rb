require 'test_helper'

class UserUpdatedEventTest < ActionView::TestCase
  should "record an event" do
    affected_user = create(:user)
    current_user = create(:user)

    UserUpdatedEvent.new(affected_user, current_user).record

    assert_equal 1, EventLog.where(event_id: EventLog::ACCOUNT_UPDATED.id).count
  end
end
