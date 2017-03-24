require 'test_helper'

class UserUpdateTest < ActionView::TestCase
  should "record an event" do
    affected_user = create(:user)
    current_user = create(:user)

    UserUpdate.new(affected_user, {}, current_user).update

    assert_equal 1, EventLog.where(event_id: EventLog::ACCOUNT_UPDATED.id).count
  end
end
