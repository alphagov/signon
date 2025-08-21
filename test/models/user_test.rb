require "test_helper"
require "bcrypt"

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    GovukEnvironment.stubs(:current).returns("production")

    @user = create(:user)
  end

  context "#authorisations" do
    should "return access tokens for user" do
      token = create(:access_token, resource_owner_id: @user.id)
      another_user = create(:user)
      token_for_another_user = create(:access_token, resource_owner_id: another_user.id)

      assert_includes @user.authorisations, token
      assert_not_includes @user.authorisations, token_for_another_user
    end

    should "not include access tokens for retired applications" do
      application = create(:application, retired: true)
      token = create(:access_token, resource_owner_id: @user.id, application:)

      assert_not_includes @user.authorisations, token
    end
  end

  context "#application_permissions" do
    should "return user application permissions for user" do
      application = create(:application)
      user_application_permission = create(:user_application_permission, user: @user, application:)

      assert_includes @user.application_permissions, user_application_permission
    end

    should "not include user application permissions for retired applications" do
      application = create(:application, retired: true)
      user_application_permission = create(:user_application_permission, user: @user, application:)

      assert_not_includes @user.application_permissions, user_application_permission
    end
  end

  context "#supported_permissions" do
    should "return supported permissions for user" do
      application = create(:application)
      supported_permission = create(:supported_permission, application:)
      create(:user_application_permission, user: @user, application:, supported_permission:)

      assert_includes @user.supported_permissions, supported_permission
    end

    should "not include supported permissions for retired applications" do
      application = create(:application, retired: true)
      supported_permission = create(:supported_permission, application:)
      create(:user_application_permission, user: @user, application:, supported_permission:)

      assert_not_includes @user.supported_permissions, supported_permission
    end
  end

  context "#require_2sv" do
    should "default to false for normal users" do
      assert_not create(:user).require_2sv?
    end

    should "default to true for admins and superadmins in production" do
      assert create(:admin_user).require_2sv?
      assert create(:superadmin_user).require_2sv?
    end

    should "default to false for admins and superadmins in non-production" do
      GovukEnvironment.stubs(:current).returns("foobar")

      assert_not create(:admin_user).require_2sv?
      assert_not create(:superadmin_user).require_2sv?
    end

    should "default to true when a user is promoted to admin" do
      user = create(:user)
      user.update!(role: Roles::Admin.name)
      assert user.require_2sv?
    end

    should "default to true when a user is promoted to superadmin" do
      user = create(:user)
      user.update!(role: Roles::Superadmin.name)
      assert user.require_2sv?
    end

    should "default to true when an admin is promoted to superadmin" do
      user = create(:admin_user)
      user.update!(role: Roles::Superadmin.name)
      assert user.require_2sv?
    end

    should "remain true when an admin is demoted" do
      user = create(:admin_user)
      user.update!(role: Roles::Normal.name)
      assert user.require_2sv?
    end

    should "default to true when a user is promoted to organisation admin" do
      user = create(:user_in_organisation)
      user.update!(role: Roles::OrganisationAdmin.name)
      assert user.require_2sv?
    end

    should "default to true when a user is promoted to super organisation admin" do
      user = create(:user_in_organisation)
      user.update!(role: Roles::SuperOrganisationAdmin.name)
      assert user.require_2sv?
    end

    should "not change if other changes are made to an admin" do
      user = create(:admin_user)
      user.update!(require_2sv: false)
      user.update!(name: "Foo Bar")
      assert_not user.require_2sv?
    end

    should "remove reason and expiry date for 2SV exemption when 2SV required" do
      user = create(:two_step_exempted_user)
      user.update!(require_2sv: true)
      assert_nil user.reason_for_2sv_exemption
      assert_nil user.expiry_date_for_2sv_exemption
    end

    should "require 2SV for the user when it is switched on for their organisation and they are not exempt" do
      organisation = create(:organisation, require_2sv: false)
      user = create(:user, organisation:)
      assert_not user.require_2sv?

      organisation.update!(require_2sv: true)
      assert user.require_2sv?
    end

    should "not require 2SV for the user when it is switched on for their organisation and they are exempt" do
      organisation = create(:organisation, require_2sv: false)
      user = create(:two_step_exempted_user, organisation:)
      assert_not user.require_2sv?

      organisation.update!(require_2sv: true)
      assert_not user.require_2sv?
    end

    should "be invalid if a new user from an organisation with mandatory 2SV but 2SV is not selected" do
      organisation = create(:organisation, require_2sv: true)
      user = build(:user, organisation:)
      assert_not user.valid?
    end
  end

  context "#send_two_step_mandated_notification?" do
    context "when not mandated" do
      should "return false" do
        assert_not @user.send_two_step_mandated_notification?
      end

      context "when mandating" do
        should "maintain after persisting" do
          @user.update!(require_2sv: true)

          assert @user.send_two_step_mandated_notification?
        end
      end

      context "when promoting a user" do
        should "be true" do
          @user.update!(role: Roles::Admin.name)

          assert @user.send_two_step_mandated_notification?
        end
      end
    end

    context "when already mandated" do
      should "return false" do
        @user.toggle(:require_2sv)

        assert_not @user.reload.send_two_step_mandated_notification?
      end
    end
  end

  context "#reset_2sv!" do
    setup do
      @super_admin   = create(:superadmin_user)
      @two_step_user = create(:two_step_enabled_user)
      @two_step_user.reset_2sv!(@super_admin)
    end

    should "persist the required attributes" do
      @two_step_user.reload

      assert_not @two_step_user.has_2sv?
      assert @two_step_user.prompt_for_2sv?
    end

    should "record the event" do
      number_of_2sv_reset_events = EventLog.where(
        event_id: EventLog::TWO_STEP_RESET.id,
        uid: @two_step_user.uid,
        initiator: @super_admin,
      ).count

      assert_equal 1, number_of_2sv_reset_events
    end
  end

  context "#prompt_for_2sv?" do
    context "when the user has already enrolled" do
      should "always be false" do
        assert_not build(:two_step_mandated_user, otp_secret_key: "welp").prompt_for_2sv?
      end
    end
  end

  test "email change tokens should expire" do
    @user = create(:user_with_pending_email_change, confirmation_sent_at: 15.days.ago)
    @user.confirm
    assert_equal "needs to be confirmed within 14 days, please request a new one", @user.errors[:email][0]
  end

  test "#cancel_email_change!" do
    original_email = "isabella.nagarkar@department.gov.uk"
    user = create(:user_with_pending_email_change, email: original_email)

    assert user.pending_reconfirmation?

    user.cancel_email_change!
    user.reload

    assert_not user.pending_reconfirmation?
    assert_equal original_email, user.email
  end

  # Scopes

  test "web_users includes non api users" do
    assert_includes User.web_users, @user
  end

  test "web_users excludes api users" do
    assert_not_includes User.web_users, create(:api_user)
  end

  test "fetches web users who signed_in X days ago" do
    create(:user, current_sign_in_at: 8.days.ago)
    signed_in_2_days_ago = create(:user, current_sign_in_at: 2.days.ago)
    create(:api_user, current_sign_in_at: 2.days.ago)

    assert_equal [signed_in_2_days_ago], User.last_signed_in_on(2.days.ago)
  end

  test "fetches web users who signed_in before X days ago" do
    create(:user, current_sign_in_at: 6.days.ago)
    signed_in_7_days_ago = create(:user, current_sign_in_at: 7.days.ago)
    signed_in_8_days_ago = create(:user, current_sign_in_at: 8.days.ago)
    create(:api_user, current_sign_in_at: 8.days.ago)

    assert_equal [signed_in_7_days_ago, signed_in_8_days_ago], User.last_signed_in_before(6.days.ago)
  end

  test "fetches web users who signed_in after X days ago" do
    signed_in_0_days_ago = create(:user, current_sign_in_at: 0.days.ago)
    signed_in_1_day_ago  = create(:user, current_sign_in_at: 1.day.ago)
    create(:user, current_sign_in_at: 2.days.ago)

    assert_equal [signed_in_0_days_ago, signed_in_1_day_ago], User.last_signed_in_after(1.day.ago)
  end

  test "fetches web users who've never signed in" do
    never_signed_in_1 = @user
    create(:user, current_sign_in_at: 1.day.ago)
    create(:user, current_sign_in_at: 1.day.ago)
    never_signed_in_2 = create(:user)

    assert_equal [never_signed_in_1, never_signed_in_2], User.never_signed_in
  end

  test "fetches web users who've never signed in and were invited to do so over 90 days ago" do
    never_signed_in_ages_ago = @user.tap(&:invite!)
    create(:user, current_sign_in_at: 1.day.ago).invite!

    Timecop.travel(91.days)

    create(:user).invite! # never signed in, invited today
    create(:user, current_sign_in_at: 1.day.ago).invite!

    assert_equal [never_signed_in_ages_ago], User.expired_never_signed_in
  end

  context ".not_recently_unsuspended" do
    should "return users who have never been unsuspended" do
      assert_includes User.not_recently_unsuspended, @user
    end

    should "not return users who have been unsuspended less than 7 days ago" do
      user2 = create(:suspended_user)
      Timecop.travel(6.days.ago) { user2.unsuspend }

      assert_not_includes User.not_recently_unsuspended, user2
    end

    should "return users who have been unsuspended more than 7 days ago" do
      user2 = create(:suspended_user)
      Timecop.travel(8.days.ago) { user2.unsuspend }

      assert_includes User.not_recently_unsuspended, user2
    end
  end

  should "encrypt otp_secret_key" do
    enabled_user = create(:two_step_enabled_user)
    assert enabled_user.encrypted_attribute?(:otp_secret_key)
  end

  context "email validation" do
    should "require an email" do
      user = build(:user, email: nil)

      assert_not user.valid?
      assert_equal ["can't be blank"], user.errors[:email]
    end

    should "accept valid emails" do
      user = build(:user)
      [
        "foo@example.com",
        "foo_bar@example.COM",
        "foo@example-domain.com",
        "user-foo+bar@really.long.domain.co.uk",
      ].each do |email|
        user.email = email

        assert user.valid?, "Expected user to be valid with email: '#{email}'"
      end
    end

    should "prevent user being created with a known non-government email address" do
      user = build(:user, email: "piers.quinn@yahoo.co.uk")

      assert_not user.valid?
      assert_equal ["not accepted. Please enter a workplace email to continue."],
                   user.errors[:email]
    end

    should "not allow user to be updated with a known non-government email address" do
      user = create(:user, email: "alexia.statham@department.gov.uk")

      user.email = "alexia.statham@yahoo.co.uk"

      assert_not user.valid?
    end

    should "reject emails with invalid domain parts" do
      user = build(:user)
      [
        "foo@example.com,",
        "foo@example_domain.com",
        "foo@no-dot-domain",
      ].each do |email|
        user.email = email

        assert_not user.valid?, "Expected user to be invalid with email: '#{email}'"
        assert_equal ["is invalid"], user.errors[:email]
      end
    end

    should "convert unicode apostrophe in email to ascii equivalent" do
      user = build(:user, email: "mario’s.castle@wii.com") # unicode apostrophe character

      assert user.valid?
      assert_equal "mario's.castle@wii.com", user.email
    end

    should "emails can't contain non-ASCII characters" do
      user = build(:user, email: "mariõs.castle@wii.com") # unicode tilde character

      assert_not user.valid?
      assert_equal ["can't contain non-ASCII characters"], user.errors[:email]
    end
  end

  context "2sv exemptions" do
    context "exempt from 2sv" do
      setup do
        @user = create(:two_step_enabled_user)
        @initiator = create(:superadmin_user)
        @expiry_date = Time.zone.today + 10
        @user.exempt_from_2sv("accessibility reasons", @initiator, @expiry_date)
      end

      should "set require 2sv to false and store the reason and expiry date" do
        assert_not @user.require_2sv?
        assert_equal "accessibility reasons", @user.reason_for_2sv_exemption
        assert_equal @expiry_date, @user.expiry_date_for_2sv_exemption
        assert_nil @user.otp_secret_key
      end

      should "record the event" do
        assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_EXEMPTED.id, uid: @user.uid, initiator: @initiator).count
      end

      context "for a admin user" do
        should "prevent them being exempted from 2SV" do
          user = build(:admin_user, reason_for_2sv_exemption: "reason")

          assert_not user.valid?
          assert_includes user.errors[:reason_for_2sv_exemption], "cannot be blank for Admin users. Remove the user's exemption to change their role."
        end
      end
    end

    context "#exempt_from_2sv??" do
      should "be true if exemption reason is present" do
        user = create(:two_step_exempted_user)
        assert user.exempt_from_2sv?
      end

      should "be false if exemption reason is nil" do
        user = create(:user)
        assert_not user.exempt_from_2sv?
      end

      should "be false if exemption reason is an empty string" do
        user = create(:user, reason_for_2sv_exemption: "")
        assert_not user.exempt_from_2sv?
      end

      should "be false if exemption reason is a string of spaces" do
        user = create(:user, reason_for_2sv_exemption: "   ")
        assert_not user.exempt_from_2sv?
      end
    end

    context "user model validity and 2sv exemptions" do
      should "be valid if 2sv exemption reason and expiry date exists" do
        user = build(:two_step_exempted_user)
        assert user.valid?
      end

      should "not be valid if 2sv exemption reason exists without expiry date" do
        user = build(:two_step_exempted_user, expiry_date_for_2sv_exemption: nil)
        assert_not user.valid?
      end

      should "not be valid if 2sv exemption expiry exists without an exemption reason" do
        user = build(:two_step_exempted_user, reason_for_2sv_exemption: nil)
        assert_not user.valid?
      end

      should "not be valid if 2sv exemption expiry exists with a blank exemption reason" do
        user = build(:two_step_exempted_user, reason_for_2sv_exemption: "   ")
        assert_not user.valid?
      end
    end
  end

  # Password Validation

  test "it requires a password to be at least 10 characters long" do
    u = build(:user, password: "dNG.c0w5!")
    assert_not u.valid?
    assert_not_empty u.errors[:password]
  end

  test "it allows very long passwords with spaces" do
    u = build(:user, password: ("4 l0nG sT!,ng " * 10)[0..127])
    u.valid?
    assert u.valid?
    assert_empty u.errors[:password]
  end

  test "it discourages weak passwords which reuse parts of the email" do
    u = build(:user, email: "sleuth@detective.com", password: "sherlock holmes baker street")
    assert u.valid?

    u = build(:user, email: "sherlock.holmes@bakerstreet.com", password: "sherlock holmes baker street")
    assert_not u.valid?
    assert_not_empty u.errors[:password]
  end

  test "unlocking an account should randomise the password" do
    original_password = "sherlock holmes baker street"
    u = build(:user, email: "sleuth@gmail.com", password: original_password)

    u.suspend "suspended for shenanigans"
    u.unsuspend

    assert_not u.valid_password?(original_password)
  end

  test "it requires a reason for suspension to suspend a user" do
    u = create(:user)
    u.suspended_at = 1.minute.ago
    assert_not u.valid?
    assert_not_empty u.errors[:reason_for_suspension]
  end

  test "suspension revokes all authorisations (`Doorkeeper::AccessToken`s)" do
    create(:access_token, resource_owner_id: @user.id)
    create(:access_token, resource_owner_id: @user.id)

    @user.suspend("Nothing personal, just needed to suspend a user for testing")

    assert @user.authorisations.all?(&:revoked?)
  end

  context "#revoke_all_authorisations" do
    should "revokes all `Doorkeeper::AccessToken`s" do
      create(:access_token, resource_owner_id: @user.id)
      create(:access_token, resource_owner_id: @user.id)

      @user.revoke_all_authorisations

      assert @user.authorisations.all?(&:revoked?)
    end

    should "skips `Doorkeeper::AccessToken`s that are already revoked" do
      first_revoked_at = create(:access_token, resource_owner_id: @user.id).tap(&:revoke).revoked_at
      second_revoked_at = create(:access_token, resource_owner_id: @user.id).tap(&:revoke).revoked_at
      create(:access_token, resource_owner_id: @user.id)
      create(:access_token, resource_owner_id: @user.id)

      Timecop.travel(1.day.from_now)

      @user.revoke_all_authorisations

      all_revoked_ats = @user.authorisations.map(&:revoked_at).compact
      assert_includes all_revoked_ats, first_revoked_at
      assert_includes all_revoked_ats, second_revoked_at
    end
  end

  test "organisation admin must belong to an organisation" do
    user = build(:user, role: Roles::OrganisationAdmin.name, organisation_id: nil)

    assert_not user.valid?
    assert_equal "can't be 'None' for Organisation admin", user.errors[:organisation_id].first
  end

  test "super organisation admin must belong to an organisation" do
    user = build(:user, role: Roles::SuperOrganisationAdmin.name, organisation_id: nil)

    assert_not user.valid?
    assert_equal "can't be 'None' for Super organisation admin", user.errors[:organisation_id].first
  end

  test "it doesn't migrate password unless correct one given" do
    password = ("4 l0nG sT!,ng " * 10)[0..127]
    old_encrypted_password = ::BCrypt::Password.create(password.to_s, cost: 10).to_s

    u = create(:user)
    u.update_column :encrypted_password, old_encrypted_password
    u.reload

    assert_not u.valid_password?("something else")
    u.reload

    assert_equal old_encrypted_password, u.encrypted_password, "Changed password"
  end

  context "#grant_permission" do
    context "where the user does not have the permission" do
      should "add the new permission"  do
        user = create(:user)
        application = create(:application)
        supported_permission = create(:supported_permission, application:)

        user.grant_permission(supported_permission)

        assert user.has_permission?(supported_permission)
      end
    end

    context "where the user has the permission" do
      should "use the existing permission" do
        user = create(:user)
        application = create(:application)
        supported_permission = create(:supported_permission, application:)
        user.supported_permissions << supported_permission

        user.grant_permission(supported_permission)

        assert user.has_permission?(supported_permission)
        assert user.supported_permissions.include?(supported_permission)
      end
    end

    context "where the user is a new user" do
      should "grant the permission" do
        user = build(:user)
        application = create(:application)
        supported_permission = create(:supported_permission, application:)

        user.grant_permission(supported_permission)

        assert user.has_permission?(supported_permission)
      end

      should "prevent the permission being granted twice" do
        user = build(:user)
        application = create(:application)
        supported_permission = create(:supported_permission, application:)

        user.grant_permission(supported_permission)
        user.grant_permission(supported_permission)
        user.save!

        assert user.has_permission?(supported_permission)
      end
    end
  end

  context "granting permissions" do
    should "grant signin permission to allow user to access the app" do
      app = create(:application)
      user = create(:user)

      assert_not user.has_access_to?(app)

      user.grant_application_signin_permission(app)

      assert user.has_access_to?(app)
    end

    should "not create duplication permission when granting an already granted permission" do
      app = create(:application)
      user = create(:user)

      user.grant_application_signin_permission(app)
      user.grant_application_signin_permission(app)

      assert_user_has_permissions [SupportedPermission::SIGNIN_NAME], app, user
    end

    should "grant permissions to user and return the created permission" do
      app = create(:application, with_non_delegated_supported_permissions: ["Create publications", "Delete publications"])
      user = create(:user)

      permission = user.grant_application_permission(app, "Create publications")

      assert_equal permission, user.application_permissions.first
      assert_user_has_permissions ["Create publications"], app, user
    end

    should "not grant permission to user for a retired application" do
      app = create(:application, retired: true, with_non_delegated_supported_permissions: %w[edit])
      user = create(:user)

      signin_permission = user.grant_application_signin_permission(app)
      edit_permission = user.grant_application_permission(app, "edit")

      assert_nil signin_permission
      assert_nil edit_permission
      assert_user_has_permissions [], app, user
    end

    should "return multiple permissions in name order" do
      app = create(:application, with_non_delegated_supported_permissions: %w[edit])
      user = create(:user)

      user.grant_application_signin_permission(app)
      user.grant_application_permission(app, "edit")

      assert_user_has_permissions ["edit", SupportedPermission::SIGNIN_NAME], app, user
    end
  end

  context "#has_permission?" do
    setup do
      @app = create(:application)
      @supported_permission = create(:supported_permission, application: @app)
    end

    context "when user is persisted" do
      setup do
        @user = create(:user)
      end

      context "when user has the permission" do
        setup do
          @user.supported_permissions << @supported_permission
        end

        should "return true" do
          assert @user.has_permission?(@supported_permission)
        end
      end

      context "when user does not have the permission" do
        should "return false" do
          assert_not @user.has_permission?(@supported_permission)
        end
      end
    end

    context "when user is not persisted" do
      setup do
        @user = build(:user)
      end

      context "when user has the permission" do
        setup do
          @user.supported_permissions << @supported_permission
        end

        should "return true" do
          assert @user.has_permission?(@supported_permission)
        end
      end

      context "when user does not have the permission" do
        should "return false" do
          assert_not @user.has_permission?(@supported_permission)
        end
      end
    end
  end

  test "inviting a user sets confirmed_at" do
    if (user = User.find_by(email: "j@1.com"))
      user.delete
    end
    user = User.invite!(name: "John Smith", email: "j@1.com")
    assert_not_nil user
    assert user.persisted?
    assert_not_nil user.confirmed_at
  end

  test "performs validations before inviting" do
    user = User.invite!(name: nil, email: "j@1.com")

    assert_not_empty user.errors
    assert_not user.persisted?
  end

  test "strips unwanted whitespace from name before creating User" do
    user = create(:user, name: "  Tina Jerković ")

    assert_equal "Tina Jerković", user.name
  end

  test "doesn't allow previously used password" do
    password = @user.password

    @user.password = "some v3ry s3cure password"
    @user.password_confirmation = "some v3ry s3cure password"
    @user.save!

    @user.password = password
    @user.password_confirmation = password

    assert_not @user.valid?
  end

  test "doesn't allow user to change to same password" do
    password = @user.password

    @user = User.find(@user.id)

    @user.password = password
    @user.password_confirmation = password
    assert_not @user.valid?
  end

  context "User status" do
    setup do
      @locked = create(:user)
      @locked.lock_access!
      @suspended = create(:user)
      @suspended.suspend("because grumble")
      @invited = User.invite!(name: "Oberyn Martell", email: "redviper@dorne.com")
    end

    context "detecting" do
      should "detect suspended" do
        assert_equal "suspended", @suspended.status
      end

      should "detect invited" do
        assert_equal "invited", @invited.status
      end

      should "detect locked" do
        assert_equal "locked", @locked.status
      end

      should "detect active" do
        assert_equal "active", @user.status
      end
    end
  end

  context "API user status" do
    setup do
      @api_user = create(:api_user)
    end

    should "return suspended" do
      @api_user.suspend("because grumble")
      assert_equal "suspended", @api_user.status
    end

    should "return locked" do
      @api_user.lock_access!
      assert_equal "locked", @api_user.status
    end

    should "return active" do
      assert_equal "active", @api_user.status
    end

    should "not return invited" do
      api_user = User.invite!(name: "Oberyn Martell", email: "redviper@dorne.com")
      api_user.update_column :api_user, true

      assert_not_equal "invited", api_user.reload.status
    end
  end

  context "#two_step_status" do
    should "return 'enabled' when user has 2SV" do
      user = build(:two_step_enabled_user)
      assert_equal User::TWO_STEP_STATUS_ENABLED, user.two_step_status
    end

    should "return 'exempt' when user has been exempted from 2SV" do
      user = build(:two_step_exempted_user)
      assert_equal User::TWO_STEP_STATUS_EXEMPTED, user.two_step_status
    end

    should "return 'not_set_up' when user does not have 2SV and has not been exempted" do
      user = build(:user)
      assert_equal User::TWO_STEP_STATUS_NOT_SET_UP, user.two_step_status
    end
  end

  context "#not_setup_2sv?" do
    should "return false when user has 2SV" do
      user = build(:two_step_enabled_user)
      assert_not user.not_setup_2sv?
    end

    should "return false when user has been exempted from 2SV" do
      user = build(:two_step_exempted_user)
      assert_not user.not_setup_2sv?
    end

    should "return true when user does not have 2SV and has not been exempted" do
      user = build(:user)
      assert user.not_setup_2sv?
    end
  end

  context "#role" do
    should "return the role class" do
      assert_equal Roles::Normal, build(:user).role
      assert_equal Roles::OrganisationAdmin, build(:organisation_admin_user).role
      assert_equal Roles::SuperOrganisationAdmin, build(:super_organisation_admin_user).role
      assert_equal Roles::Admin, build(:admin_user).role
      assert_equal Roles::Superadmin, build(:superadmin_user).role
    end
  end

  context "#role_name" do
    should "return the role name" do
      assert_equal Roles::Normal.name, build(:user).role_name
      assert_equal Roles::OrganisationAdmin.name, build(:organisation_admin_user).role_name
      assert_equal Roles::SuperOrganisationAdmin.name, build(:super_organisation_admin_user).role_name
      assert_equal Roles::Admin.name, build(:admin_user).role_name
      assert_equal Roles::Superadmin.name, build(:superadmin_user).role_name
    end

    should "return nil if the role isn't set" do
      assert_nil build(:user, role: nil).role_name
    end
  end

  context "#manageable_roles" do
    should "return roles that the user is allowed to manage" do
      assert_equal [], build(:user).manageable_roles
      assert_equal [Roles::Normal, Roles::OrganisationAdmin], build(:organisation_admin_user).manageable_roles
      assert_equal [Roles::Normal, Roles::OrganisationAdmin, Roles::SuperOrganisationAdmin], build(:super_organisation_admin_user).manageable_roles
      assert_equal [Roles::Normal, Roles::OrganisationAdmin, Roles::SuperOrganisationAdmin, Roles::Admin], build(:admin_user).manageable_roles
      assert_equal [Roles::Normal, Roles::OrganisationAdmin, Roles::SuperOrganisationAdmin, Roles::Admin, Roles::Superadmin], build(:superadmin_user).manageable_roles
    end
  end

  context "#can_manage?" do
    should "indicate whether user is allowed to manage another user" do
      assert_not build(:user).can_manage?(build(:user))
      assert_not build(:user).can_manage?(build(:organisation_admin_user))
      assert_not build(:user).can_manage?(build(:super_organisation_admin_user))
      assert_not build(:user).can_manage?(build(:admin_user))
      assert_not build(:user).can_manage?(build(:superadmin_user))

      assert build(:organisation_admin_user).can_manage?(build(:user))
      assert build(:organisation_admin_user).can_manage?(build(:organisation_admin_user))
      assert_not build(:organisation_admin_user).can_manage?(build(:super_organisation_admin_user))
      assert_not build(:organisation_admin_user).can_manage?(build(:admin_user))
      assert_not build(:organisation_admin_user).can_manage?(build(:superadmin_user))

      assert build(:super_organisation_admin_user).can_manage?(build(:user))
      assert build(:super_organisation_admin_user).can_manage?(build(:organisation_admin_user))
      assert build(:super_organisation_admin_user).can_manage?(build(:super_organisation_admin_user))
      assert_not build(:super_organisation_admin_user).can_manage?(build(:admin_user))
      assert_not build(:super_organisation_admin_user).can_manage?(build(:superadmin_user))

      assert build(:admin_user).can_manage?(build(:user))
      assert build(:admin_user).can_manage?(build(:organisation_admin_user))
      assert build(:admin_user).can_manage?(build(:super_organisation_admin_user))
      assert build(:admin_user).can_manage?(build(:admin_user))
      assert_not build(:admin_user).can_manage?(build(:superadmin_user))

      assert build(:superadmin_user).can_manage?(build(:user))
      assert build(:superadmin_user).can_manage?(build(:organisation_admin_user))
      assert build(:superadmin_user).can_manage?(build(:super_organisation_admin_user))
      assert build(:superadmin_user).can_manage?(build(:admin_user))
      assert build(:superadmin_user).can_manage?(build(:superadmin_user))
    end
  end

  context "#manageable_organisations" do
    should "return relation for organisations that the user is allowed to manage" do
      organisation = create(:organisation, name: "Org1")
      child_organisation = create(:organisation, parent: organisation, name: "Org2")
      create(:organisation, name: "Org3")

      assert_equal [], create(:user, organisation:).manageable_organisations
      assert_equal [organisation], create(:organisation_admin_user, organisation:).manageable_organisations
      assert_equal [organisation, child_organisation], create(:super_organisation_admin_user, organisation:).manageable_organisations
      assert_equal Organisation.all, create(:admin_user, organisation:).manageable_organisations
      assert_equal Organisation.all, create(:superadmin_user, organisation:).manageable_organisations
    end
  end

  context "authorised applications" do
    setup do
      @user = create(:user)
      @app = create(:application)
      authenticate_access(@user, @app)
    end

    should "include applications the user is authorised for" do
      assert_includes @user.authorised_applications, @app
    end

    should "not include applications the user is not authorised for" do
      unused_app = create(:application)
      assert_not_includes @user.authorised_applications, unused_app
    end

    should "only include each application once" do
      authenticate_access(@user, @app)
      assert_equal 1, @user.authorised_applications.count
    end
  end

  context ".send_reset_password_instructions" do
    context "for a suspended user" do
      should "return the user" do
        user = create(:suspended_user)
        assert_equal user, User.send_reset_password_instructions(email: user.email)
      end

      should "notify them that reset password is disallowed and not send reset instructions" do
        user = create(:suspended_user)

        assert_enqueued_jobs 1 do
          User.send_reset_password_instructions(email: user.email)
        end
      end
    end
  end

  context "#event_logs" do
    should "return all of user's EventLogs" do
      user = create(:user)
      create(:event_log, uid: user.uid, event_id: EventLog::UNSUCCESSFUL_LOGIN.id)
      create(:event_log, uid: user.uid, event_id: EventLog::SUCCESSFUL_LOGIN.id)

      assert_equal 2, user.event_logs.count
    end

    should "filter user's EventLogs by event type when an argument is given" do
      user = create(:user)
      create(:event_log, uid: user.uid, event_id: EventLog::UNSUCCESSFUL_LOGIN.id)
      create(:event_log, uid: user.uid, event_id: EventLog::SUCCESSFUL_LOGIN.id)

      assert_equal 1, user.event_logs(event: EventLog::SUCCESSFUL_LOGIN).count
    end
  end

  context ".suspended" do
    should "only return suspended users" do
      suspended_user = create(:suspended_user)

      assert_equal [suspended_user], User.suspended
    end
  end

  context ".not_suspended" do
    should "only return users that have not been suspended" do
      create(:suspended_user)
      active_user = create(:active_user)

      assert_equal [@user, active_user], User.not_suspended
    end
  end

  context ".invited" do
    should "only return users that have been invited but have not accepted" do
      invited_user = create(:invited_user)
      create(:active_user)

      assert_equal [invited_user], User.invited
    end
  end

  context ".not_invited" do
    should "only return users that have not been invited or have accepted" do
      create(:invited_user)
      active_user = create(:active_user)

      assert_equal [@user, active_user], User.not_invited
    end
  end

  context ".locked" do
    should "only return users that have been locked" do
      locked_user = create(:locked_user)
      create(:active_user)

      assert_equal [locked_user], User.locked
    end
  end

  context ".not_locked" do
    should "only return users that have not been locked" do
      create(:locked_user)
      active_user = create(:active_user)

      assert_equal [@user, active_user], User.not_locked
    end
  end

  context ".active" do
    should "only return users that are considered active" do
      create(:invited_user)
      create(:locked_user)
      create(:suspended_user)
      active_user = create(:active_user)

      assert_equal [@user, active_user], User.active
    end
  end

  context ".exempt_from_2sv" do
    should "only return users that have been exempted from 2SV" do
      exempted_user = create(:two_step_exempted_user)
      create(:two_step_enabled_user)

      assert_equal [exempted_user], User.exempt_from_2sv
    end
  end

  context ".not_exempt_from_2sv" do
    should "only return users that have not been exempted from 2SV" do
      create(:two_step_exempted_user)
      enabled_user = create(:two_step_enabled_user)

      assert_equal [@user, enabled_user], User.not_exempt_from_2sv
    end
  end

  context ".has_2sv" do
    should "only return users that have 2SV" do
      create(:two_step_exempted_user)
      enabled_user = create(:two_step_enabled_user)

      assert_equal [enabled_user], User.has_2sv
    end
  end

  context ".does_not_have_2sv" do
    should "only return users that do not have 2SV" do
      exempted_user = create(:two_step_exempted_user)
      create(:two_step_enabled_user)

      assert_equal [@user, exempted_user], User.does_not_have_2sv
    end
  end

  context ".not_setup_2sv" do
    should "only return users that have not been exempted from 2SV and do not have 2SV" do
      not_set_up_user = create(:user)
      create(:two_step_exempted_user)
      create(:two_step_enabled_user)

      assert_equal [@user, not_set_up_user], User.not_setup_2sv
    end
  end

  context ".with_partially_matching_name" do
    should "only return users with a name that includes the value" do
      user1 = create(:user, name: "does-match1")
      user2 = create(:user, name: "does-match2")
      create(:user, name: "does-not-match")

      assert_equal [user1, user2], User.with_partially_matching_name("does-match")
    end
  end

  context ".with_partially_matching_email" do
    should "only return users with an email that includes the value" do
      user1 = create(:user, email: "does-match1@example.com")
      user2 = create(:user, email: "does-match2@example.com")
      create(:user, email: "does-not-match@example.com")

      assert_equal [user1, user2], User.with_partially_matching_email("does-match")
    end
  end

  context ".with_partially_matching_name_or_email" do
    should "only return users with a name OR email that includes the value" do
      user1 = create(:user, name: "does-match", email: "does-not-match@example.com")
      user2 = create(:user, name: "does-not-match", email: "does-match@example.com")
      create(:user, name: "does-not-match", email: "does-not-match-either@example.com")

      assert_equal [user1, user2], User.with_partially_matching_name_or_email("does-match")
    end
  end

  context ".with_statuses" do
    should "only return suspended or invited users" do
      suspended_user = create(:suspended_user)
      invited_user = create(:invited_user)
      create(:locked_user)
      create(:active_user)

      assert_equal [suspended_user, invited_user], User.with_statuses(%w[suspended invited])
    end

    should "only return active or locked users" do
      create(:suspended_user)
      create(:invited_user)
      locked_user = create(:locked_user)
      active_user = create(:active_user)

      assert_equal [@user, locked_user, active_user], User.with_statuses(%w[active locked])
    end

    should "return all users if no statuses specified" do
      suspended_user = create(:suspended_user)
      invited_user = create(:invited_user)
      locked_user = create(:locked_user)
      active_user = create(:active_user)

      assert_equal [@user, suspended_user, invited_user, locked_user, active_user], User.with_statuses([])
    end

    should "ignore any non-existent statuses" do
      suspended_user = create(:suspended_user)
      invited_user = create(:invited_user)
      locked_user = create(:locked_user)
      active_user = create(:active_user)

      assert_equal [@user, suspended_user, invited_user, locked_user, active_user], User.with_statuses(%w[non-existent])
    end
  end

  context ".with_2sv_statuses" do
    should "only return not_set_up and exempted users" do
      not_set_up_user = create(:user)
      exempted_user = create(:two_step_exempted_user)
      create(:two_step_enabled_user)

      assert_equal [@user, not_set_up_user, exempted_user], User.with_2sv_statuses(%w[not_setup_2sv exempt_from_2sv])
    end

    should "only return enabled users" do
      create(:user)
      create(:two_step_exempted_user)
      enabled_user = create(:two_step_enabled_user)

      assert_equal [enabled_user], User.with_2sv_statuses(%w[has_2sv])
    end

    should "return all users if no statuses specified" do
      not_set_up_user = create(:user)
      exempted_user = create(:two_step_exempted_user)
      enabled_user = create(:two_step_enabled_user)

      assert_equal [@user, not_set_up_user, exempted_user, enabled_user], User.with_2sv_statuses([])
    end

    should "ignore any non-existent statuses" do
      not_set_up_user = create(:user)
      exempted_user = create(:two_step_exempted_user)
      enabled_user = create(:two_step_enabled_user)

      assert_equal [@user, not_set_up_user, exempted_user, enabled_user], User.with_2sv_statuses(%w[non-existent])
    end
  end

  context ".with_role" do
    should "only return users with specified role(s)" do
      admin_user = create(:admin_user)
      organisation_admin = create(:organisation_admin_user)
      create(:user)

      assert_equal [admin_user, organisation_admin], User.with_role(%w[admin organisation_admin])
    end
  end

  context ".with_permission" do
    should "only return users with specified permission(s)" do
      app1 = create(:application)
      app2 = create(:application)

      permission1 = create(:supported_permission, application: app1)

      user1 = create(:user, supported_permissions: [app1.signin_permission, permission1])
      create(:user, supported_permissions: [])
      user2 = create(:user, supported_permissions: [app2.signin_permission, permission1])

      specified_permissions = [app1.signin_permission, app2.signin_permission]
      assert_equal [user1, user2], User.with_permission(specified_permissions.map(&:to_param))
    end

    should "only return a user once even when they have two permissions for the same app" do
      app = create(:application)

      permission = create(:supported_permission, application: app)
      create(:user, supported_permissions: [app.signin_permission, permission])

      specified_permissions = [app.signin_permission, permission]
      assert_equal 1, User.with_permission(specified_permissions.map(&:to_param)).count
    end
  end

  context ".with_organisation" do
    should "only return users with specified organisation(s)" do
      org1 = create(:organisation)
      org2 = create(:organisation)
      org3 = create(:organisation)

      user_in_org1 = create(:user, organisation: org1)
      create(:user, organisation: org2)
      user_in_org3 = create(:user, organisation: org3)

      assert_equal [user_in_org1, user_in_org3], User.with_organisation([org1, org3].map(&:to_param))
    end
  end

  context ".with_default_permissions" do
    should "return a new user with default permissions added" do
      application = create(:application)
      create(:supported_permission, default: true, application:)

      user = User.with_default_permissions

      assert 1, user.supported_permissions.size
    end
  end

  context "#organisation_name" do
    should "return organisation name if user has organisation" do
      organisation = build(:organisation, name: "organisation-name")
      assert_equal "organisation-name", build(:user, organisation:).organisation_name
    end

    should "return 'None' if user has no organisation" do
      assert_equal Organisation::NONE, build(:user).organisation_name
    end
  end

  context "#web_user?" do
    should "return true for non-API user" do
      assert build(:user).web_user?
    end

    should "return false for API user" do
      assert_not build(:api_user).web_user?
    end
  end

  context "#anonymous_user_id" do
    should "be nil if ANONYMOUS_USER_ID_SECRET is unset" do
      ClimateControl.modify ANONYMOUS_USER_ID_SECRET: nil do
        assert_nil build(:user).anonymous_user_id
      end
    end

    should "be computed based on the uid and ANONYMOUS_USER_ID_SECRET" do
      ClimateControl.modify ANONYMOUS_USER_ID_SECRET: "some-anonymous-user-id-secret" do
        assert_equal "8724f603978a3adc0", build(:user, uid: "some-user-id").anonymous_user_id
        assert_equal "69d0cf995988be2e1", build(:user, uid: "some-other-user-id").anonymous_user_id
      end

      ClimateControl.modify ANONYMOUS_USER_ID_SECRET: "other-anonymous-user-id-secret" do
        assert_equal "297069f42a9251c64", build(:user, uid: "some-user-id").anonymous_user_id
        assert_equal "4a3c66e26f5ec4229", build(:user, uid: "other-user-id").anonymous_user_id
      end
    end
  end

  def authenticate_access(user, app)
    Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: app.id)
  end

  def assert_user_has_permissions(expected_permissions, application, user)
    permissions = user.permissions_for(application)
    assert_equal expected_permissions, permissions
  end
end
