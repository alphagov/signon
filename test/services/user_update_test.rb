require "test_helper"
require "ipaddr"

class UserUpdateTest < ActionView::TestCase
  attr_reader :current_user, :affected_user, :ip_address

  setup do
    @current_user = create(:superadmin_user)
    @affected_user = create(:user)
    @affected_user.name = "different-name"
    @ip_address = "1.2.3.4"
  end

  should "record an event" do
    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, {}).call
    end

    assert_equal 1, EventLog.where(event_id: EventLog::ACCOUNT_UPDATED.id).count
  end

  should "records permission changes" do
    parsed_ip_address = IPAddr.new(ip_address, Socket::AF_INET).to_s

    app = create(:application, name: "App", with_supported_permissions: ["Editor", SupportedPermission::SIGNIN_NAME, "Something Else"])
    affected_user.grant_application_permission(app, "Something Else")

    perms = app.supported_permissions.first(2).map(&:id)
    params = { supported_permission_ids: perms }
    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end

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
    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end

    add_event = EventLog.where(event_id: EventLog::PERMISSIONS_ADDED.id).last
    logged_permissions = add_event.trailing_message.sub(/^\(/, "").sub(/\)$/, "").gsub(/ /, "").split(",")

    assert Set.new(permissions).subset?(Set.new(logged_permissions))
  end

  should "record when 2SV exemption has been removed" do
    @affected_user = create(:two_step_exempted_user)

    params = { require_2sv: "1" }
    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end

    assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_EXEMPTION_REMOVED.id).count
  end

  should "record when 2SV has been mandated" do
    params = { require_2sv: "1" }
    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end

    assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_MANDATED.id).count
  end

  should "not lose permissions when supported_permissions are absent from params" do
    app = create(:application)
    affected_user.grant_application_signin_permission(app)
    assert affected_user.has_access_to?(app)

    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, {}).call
    end

    assert affected_user.has_access_to?(app)
  end

  should "record when organisation has been changed" do
    organisation_1 = create(:organisation, name: "organisation-1")
    organisation_2 = create(:organisation, name: "organisation-2")
    affected_user = create(:user, organisation: organisation_1)

    params = { organisation_id: organisation_2.id }
    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end

    assert_equal 1, EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).count
    assert_equal "from organisation-1 to organisation-2", EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).last.trailing_message
  end

  should "record when organisation has been changed from 'None'" do
    organisation = create(:organisation, name: "organisation-name")
    @affected_user = create(:user, organisation: nil)

    params = { organisation_id: organisation.id }
    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end

    assert_equal 1, EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).count
    assert_equal "from None to organisation-name", EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).last.trailing_message
  end

  should "record when organisation has been changed to 'None'" do
    organisation = create(:organisation, name: "organisation-name")
    @affected_user = create(:user, organisation:)

    params = { organisation_id: nil }
    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end

    assert_equal 1, EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).count
    assert_equal "from organisation-name to None", EventLog.where(event_id: EventLog::ORGANISATION_CHANGED.id).last.trailing_message
  end

  should "record email change if value of email attribute has changed" do
    params = { email: "new@gov.uk" }
    EventLog.expects(:record_email_change).with(affected_user, affected_user.email, "new@gov.uk")

    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end
  end

  should "not record email change if value of email attribute has not changed" do
    params = { email: affected_user.email }
    EventLog.expects(:record_email_change).never

    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end
  end

  should "invite user if email has changed, user has been invited, and user is a web user" do
    params = { email: "new@gov.uk" }
    @affected_user = create(:invited_user)
    affected_user.expects(:invite!)

    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end
  end

  should "not invite user if email has changed and user is a web user, but user has not been invited" do
    params = { email: "new@gov.uk" }
    @affected_user = create(:user)
    affected_user.expects(:invite!).never

    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end
  end

  should "not invite user if email has changed, user has been invited, but user is an API user" do
    params = { email: "new@gov.uk" }
    @affected_user = create(:api_user, :invited)
    affected_user.expects(:invite!).never

    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end
  end

  should "notify user if email has changed and user is a web user" do
    params = { email: "new@gov.uk" }

    mail_to_old_email = mock("mail-to-old-email")
    UserMailer.stubs(:email_changed_by_admin_notification).with(
      affected_user, affected_user.email, affected_user.email
    ).returns(mail_to_old_email)
    mail_to_old_email.expects(:deliver_later)

    mail_to_new_email = mock("mail-to-new-email")
    UserMailer.stubs(:email_changed_by_admin_notification).with(
      affected_user, affected_user.email, "new@gov.uk"
    ).returns(mail_to_new_email)
    mail_to_new_email.expects(:deliver_later)

    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end
  end

  should "not notify user if user is a web user, but email has not changed" do
    params = { email: affected_user.email }
    UserMailer.expects(:email_changed_by_admin_notification).never

    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end
  end

  should "not notify user if email has changed, but user is an API user" do
    params = { email: "new@gov.uk" }
    @affected_user = create(:api_user)
    UserMailer.expects(:email_changed_by_admin_notification).never

    with_current(user: current_user, user_ip: ip_address) do
      UserUpdate.new(affected_user, params).call
    end
  end
end
