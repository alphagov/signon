require "test_helper"

class OrganisationUsersSuspenderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @organisation = create(:organisation, slug: "government-digital-service")
    @reason_for_suspension = "reason for suspension"
  end

  test "suspends users who belong to the organisation" do
    organisation_user = create(:user, organisation: @organisation)

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).suspend

    organisation_user.reload

    assert organisation_user.suspended?
    assert_equal organisation_user.reason_for_suspension, @reason_for_suspension
  end

  test "doesn't modify users who belong to other organisations" do
    other_reason_for_suspension = "traitor"

    suspended_user = create(:user, organisation: create(:organisation, slug: "other-organisation"), suspended_at: Time.zone.today, reason_for_suspension: other_reason_for_suspension)

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).suspend

    suspended_user.reload

    assert suspended_user.suspended?
    assert_equal suspended_user.reason_for_suspension, other_reason_for_suspension

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).unsuspend

    assert suspended_user.reload.suspended?
  end

  test "doesn't modify users who are suspended for other reasons" do
    other_reason_for_suspension = "traitor"

    suspended_user = create(:user, organisation: create(:organisation, slug: "other-organisation"), suspended_at: Time.zone.today, reason_for_suspension: other_reason_for_suspension)

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).suspend

    suspended_user.reload

    assert suspended_user.suspended?
    assert_equal suspended_user.reason_for_suspension, other_reason_for_suspension

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).unsuspend

    assert suspended_user.reload.suspended?
  end

  test "returns the count of users who got suspended" do
    create_list(:user, 2, organisation: @organisation)

    assert_equal 2, OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).suspend
  end

  test "records suspension in event log" do
    users = create_list(:user, 2, organisation: @organisation)
    users.each do |user|
      EventLog.expects(:record_event)
        .with(responds_with(:email, user.email), EventLog::ACCOUNT_BULK_SUSPENDED)
    end

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).suspend
  end

  test "sends suspension notification to users who got suspended" do
    users = create_list(:user, 2, organisation: @organisation)

    mailer = mock
    mailer.expects(:deliver_now).returns(true).twice
    users.each do |user|
      UserMailer.expects(:suspension_notification)
        .with(responds_with(:email, user.email))
        .returns(mailer)
    end

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).suspend
  end

  test "syncs permissions with downstream apps to inform them about suspension" do
    user = create(:user, organisation: @organisation)
    PermissionUpdater.expects(:perform_on).with(user)

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).suspend
  end

  test "enforces downstream apps to log-off the suspended user" do
    user = create(:user, organisation: @organisation)
    ReauthEnforcer.expects(:perform_on).with(user)

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).suspend
  end

  test "revokes all authorisations (`Doorkeeper::AccessToken`s)" do
    user = create(:user, organisation: @organisation)
    create(:access_token, resource_owner_id: user.id)
    create(:access_token, resource_owner_id: user.id)

    OrganisationUsersSuspender.new(organisation: @organisation, reason_for_suspension: @reason_for_suspension).suspend

    assert user.authorisations.all?(&:revoked?)
  end
end
