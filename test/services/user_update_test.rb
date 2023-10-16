require "test_helper"
require "ipaddr"

class UserUpdateTest < ActionView::TestCase
  should "record an event" do
    affected_user = create(:user)
    current_user = create(:superadmin_user)
    ip_address = "1.2.3.4"

    UserUpdate.new(affected_user, {}, current_user, ip_address).call

    assert_equal 1, EventLog.where(event_id: EventLog::ACCOUNT_UPDATED.id).count
  end

  should "records permission changes" do
    current_user = create(:superadmin_user)
    ip_address = "1.2.3.4"
    parsed_ip_address = IPAddr.new(ip_address, Socket::AF_INET).to_s

    affected_user = create(:user)
    app = create(:application, name: "App", with_supported_permissions: ["Editor", SupportedPermission::SIGNIN_NAME, "Something Else"])
    affected_user.grant_application_permission(app, "Something Else")

    perms = app.supported_permissions.first(2).map(&:id)
    params = { supported_permission_ids: perms }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    add_event = EventLog.where(event_id: EventLog::PERMISSIONS_ADDED.id).last
    assert ["(Editor, signin)", "(signin, Editor)"].include?(add_event.trailing_message)
    assert_equal current_user, add_event.initiator
    assert_equal app.id, add_event.application_id
    assert_equal parsed_ip_address, add_event.ip_address_string

    add_event = EventLog.where(event_id: EventLog::PERMISSIONS_REMOVED.id).last
    assert_equal "(Something Else)", add_event.trailing_message
    assert_equal current_user, add_event.initiator
    assert_equal app.id, add_event.application_id
    assert_equal parsed_ip_address, add_event.ip_address_string
  end

  should "log the addition of a large number of permissions" do
    current_user = create(:superadmin_user)
    ip_address = "1.2.3.4"

    affected_user = create(:user)
    permissions = (0..100).map { |i| "permission-#{i}" }
    app = create(:application, name: "App", with_supported_permissions: permissions)

    params = { supported_permission_ids: app.supported_permissions.map(&:id) }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    add_event = EventLog.where(event_id: EventLog::PERMISSIONS_ADDED.id).last
    logged_permissions = add_event.trailing_message.sub(/^\(/, "").sub(/\)$/, "").gsub(/ /, "").split(",")

    assert Set.new(permissions).subset?(Set.new(logged_permissions))
  end

  should "record when 2SV exemption has been removed" do
    current_user = create(:superadmin_user)
    ip_address = "1.2.3.4"

    affected_user = create(:two_step_exempted_user)

    params = { require_2sv: "1" }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_EXEMPTION_REMOVED.id).count
  end

  should "record when 2SV has been mandated" do
    current_user = create(:superadmin_user)
    ip_address = "1.2.3.4"

    affected_user = create(:user)

    params = { require_2sv: "1" }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_MANDATED.id).count
  end

  should "not lose permissions when supported_permissions are absent from params" do
    current_user = create(:superadmin_user)
    ip_address = "1.2.3.4"

    affected_user = create(:user)
    app = create(:application)
    affected_user.grant_application_signin_permission(app)
    assert affected_user.has_access_to?(app)

    UserUpdate.new(affected_user, {}, current_user, ip_address).call

    assert affected_user.has_access_to?(app)
  end
end
