require 'test_helper'

class UserUpdateTest < ActionView::TestCase
  should "record an event" do
    affected_user = create(:user)
    current_user = create(:superadmin_user)

    UserUpdate.new(affected_user, {}, current_user).update

    assert_equal 1, EventLog.where(event_id: EventLog::ACCOUNT_UPDATED.id).count
  end

  should "records permission changes" do
    current_user = create(:superadmin_user)

    affected_user = create(:user)
    app = create(:application, name: "App", with_supported_permissions: ["Editor", "signin", "Something Else"])
    affected_user.grant_application_permission(app, 'Something Else')

    perms = app.supported_permissions.first(2).map(&:id)
    params = { supported_permission_ids: perms }
    UserUpdate.new(affected_user, params, current_user).update

    add_event = EventLog.where(event_id: EventLog::PERMISSIONS_ADDED.id).last
    assert ["(Editor, signin)", "(signin, Editor)"].include?(add_event.trailing_message)
    assert_equal current_user, add_event.initiator
    assert_equal app.id, add_event.application_id

    add_event = EventLog.where(event_id: EventLog::PERMISSIONS_REMOVED.id).last
    assert_equal "(Something Else)", add_event.trailing_message
    assert_equal current_user, add_event.initiator
    assert_equal app.id, add_event.application_id
  end
end
