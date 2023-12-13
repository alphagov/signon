require "test_helper"
require "ipaddr"

class UserUpdateTest < ActionView::TestCase
  attr_reader :current_user, :affected_user, :ip_address

  setup do
    @current_user = create(:superadmin_user)
    @affected_user = create(:user)
    @ip_address = "1.2.3.4"
  end

  should "record an event" do
    UserUpdate.new(affected_user, {}, current_user, ip_address).call

    assert_equal 1, EventLog.where(event_id: EventLog::ACCOUNT_UPDATED.id).count
  end

  should "records permission changes" do
    parsed_ip_address = IPAddr.new(ip_address, Socket::AF_INET).to_s

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
    permissions = (0..100).map { |i| "permission-#{i}" }
    app = create(:application, name: "App", with_supported_permissions: permissions)

    params = { supported_permission_ids: app.supported_permissions.map(&:id) }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    add_event = EventLog.where(event_id: EventLog::PERMISSIONS_ADDED.id).last
    logged_permissions = add_event.trailing_message.sub(/^\(/, "").sub(/\)$/, "").gsub(/ /, "").split(",")

    assert Set.new(permissions).subset?(Set.new(logged_permissions))
  end

  should "record when 2SV exemption has been removed" do
    @affected_user = create(:two_step_exempted_user)

    params = { require_2sv: "1" }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_EXEMPTION_REMOVED.id).count
  end

  should "record when 2SV has been mandated" do
    params = { require_2sv: "1" }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_MANDATED.id).count
  end

  should "not lose permissions when supported_permissions are absent from params" do
    app = create(:application)
    affected_user.grant_application_signin_permission(app)
    assert affected_user.has_access_to?(app)

    UserUpdate.new(affected_user, {}, current_user, ip_address).call

    assert affected_user.has_access_to?(app)
  end

  should "record when organisation has been changed" do
    organisation_1 = create(:organisation, name: "organisation-1")
    organisation_2 = create(:organisation, name: "organisation-2")
    affected_user = create(:user, organisation: organisation_1)

    params = { organisation_id: organisation_2.id }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    assert_equal 1, EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).count
    assert_equal "from organisation-1 to organisation-2", EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).last.trailing_message
  end

  should "record when organisation has been changed from 'None'" do
    organisation = create(:organisation, name: "organisation-name")
    @affected_user = create(:user, organisation: nil)

    params = { organisation_id: organisation.id }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    assert_equal 1, EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).count
    assert_equal "from None to organisation-name", EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).last.trailing_message
  end

  should "record when organisation has been changed to 'None'" do
    organisation = create(:organisation, name: "organisation-name")
    @affected_user = create(:user, organisation:)

    params = { organisation_id: nil }
    UserUpdate.new(affected_user, params, current_user, ip_address).call

    assert_equal 1, EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).count
    assert_equal "from organisation-name to None", EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).last.trailing_message
  end
end
