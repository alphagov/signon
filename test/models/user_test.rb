# coding: utf-8
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = create(:user)
  end

  test "`requires_2sv` defaults to false" do
    refute build(:user).requires_2sv?
  end

  test "email change tokens should expire" do
    @user = create(:user_with_pending_email_change, confirmation_sent_at: 15.days.ago)
    @user.confirm
    assert_equal "needs to be confirmed within 14 days, please request a new one", @user.errors[:email][0]
  end

  # Scopes

  test "web_users includes non api users" do
    assert_includes User.web_users, @user
  end

  test "web_users excludes api users" do
    assert_not_includes User.web_users, create(:api_user)
  end

  test "fetches web users who signed_in X days ago" do
    signed_in_8_days_ago = create(:user, current_sign_in_at: 8.days.ago)
    signed_in_2_days_ago = create(:user, current_sign_in_at: 2.days.ago)
    api_user = create(:api_user, current_sign_in_at: 2.days.ago)

    assert_equal [signed_in_2_days_ago], User.last_signed_in_on(2.days.ago)
  end

  test "fetches web users who signed_in before X days ago" do
    signed_in_6_days_ago = create(:user, current_sign_in_at: 6.days.ago)
    signed_in_7_days_ago = create(:user, current_sign_in_at: 7.days.ago)
    signed_in_8_days_ago = create(:user, current_sign_in_at: 8.days.ago)
    api_user = create(:api_user, current_sign_in_at: 8.days.ago)

    assert_equal [signed_in_7_days_ago, signed_in_8_days_ago], User.last_signed_in_before(6.days.ago)
  end

  test "fetches web users who signed_in after X days ago" do
    signed_in_0_days_ago = create(:user, current_sign_in_at: 0.days.ago)
    signed_in_1_day_ago  = create(:user, current_sign_in_at: 1.day.ago)
    signed_in_2_days_ago = create(:user, current_sign_in_at: 2.days.ago)

    assert_equal [signed_in_0_days_ago, signed_in_1_day_ago], User.last_signed_in_after(1.day.ago)
  end

  context ".with_role" do
    setup do
      @admin = create(:admin_user)
      @normal = create(:user)
    end

    should "return users with specified role" do
      assert_includes User.with_role(:admin), @admin
    end

    should "not return users with a role other than the specified role" do
      assert_not_includes User.with_role(:admin), @normal
    end
  end

  context ".not_recently_unsuspended" do
    should "return users who have never been unsuspended" do
      assert_includes User.not_recently_unsuspended, @user
    end

    should "not return users who have been unsuspended less than 3 days ago" do
      user2 = create(:suspended_user)
      Timecop.travel(2.days.ago) { user2.unsuspend }

      assert_not_includes User.not_recently_unsuspended, user2
    end

    should "return users who have been unsuspended more than 3 days ago" do
      user2 = create(:suspended_user)
      Timecop.travel(4.days.ago) { user2.unsuspend }

      assert_includes User.not_recently_unsuspended, user2
    end
  end

  context "email validation" do
    should "require an email" do
      user = build(:user, email: nil)

      refute user.valid?
      assert_equal ["can't be blank"], user.errors[:email]
    end

    should "accept valid emails" do
      user = build(:user)
      [
        'foo@example.com',
        'foo_bar@example.COM',
        'foo@example-domain.com',
        'user-foo+bar@really.long.domain.co.uk',
      ].each do |email|
        user.email = email

        assert user.valid?, "Expected user to be valid with email: '#{email}'"
      end
    end

    should "reject emails with invalid domain parts" do
      user = build(:user)
      [
        'foo@example.com,',
        'foo@example_domain.com',
        'foo@no-dot-domain',
      ].each do |email|
        user.email = email

        refute user.valid?, "Expected user to be invalid with email: '#{email}'"
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

      refute user.valid?
      assert_equal ["can't contain non-ASCII characters"], user.errors[:email]
    end
  end

  # Password Validation

  test "it requires a password to be at least 10 characters long" do
    u = build(:user, password: "dNG.c0w5!")
    refute u.valid?
    assert_not_empty u.errors[:password]
  end

  test "it allows very long passwords with spaces" do
    u = build(:user, password: ("4 l0nG sT!,ng " * 10)[0..127])
    u.valid?
    assert u.valid?
    assert_empty u.errors[:password]
  end

  test "it discourages weak passwords which reuse parts of the email" do
    u = build(:user, email: "sleuth@gmail.com", password: "sherlock holmes baker street")
    assert u.valid?

    u = build(:user, email: "sherlock.holmes@bakerstreet.com", password: "sherlock holmes baker street")
    refute u.valid?
    assert_not_empty u.errors[:password]
  end

  test "it requires a reason for suspension to suspend a user" do
    u = create(:user)
    u.suspended_at = 1.minute.ago
    refute u.valid?
    assert_not_empty u.errors[:reason_for_suspension]
  end

  test "organisation admin must belong to an organisation" do
    user = build(:user, role: 'organisation_admin', organisation_id: nil)

    refute user.valid?
    assert_equal "can't be 'None' for an Organisation admin", user.errors[:organisation_id].first
  end

  test "it doesn't migrate password unless correct one given" do
    password = ("4 l0nG sT!,ng " * 10)[0..127]
    old_encrypted_password = ::BCrypt::Password.create("#{password}", cost: 10).to_s

    u = create(:user)
    u.update_column :encrypted_password, old_encrypted_password
    u.reload

    refute u.valid_password?("something else")
    u.reload

    assert_equal old_encrypted_password, u.encrypted_password, "Changed passphrase"
  end

  test "can grant permissions to users and return the created permission" do
    app = create(:application, name: "my_app", with_supported_permissions: ['Create publications', 'Delete publications'])
    user = create(:user)

    permission = user.grant_application_permission(app, "Create publications")

    assert_equal permission, user.application_permissions.first
    assert_user_has_permissions ['Create publications'], app, user
  end

  test "granting an already granted permission doesn't cause duplicates" do
    app = create(:application, name: "my_app")
    user = create(:user)

    user.grant_application_permission(app, "signin")
    user.grant_application_permission(app, "signin")

    assert_user_has_permissions ['signin'], app, user
  end

  test "returns multiple permissions in name order" do
    app = create(:application, name: "my_app", with_supported_permissions: ["edit"])
    user = create(:user)

    user.grant_application_permission(app, "signin")
    user.grant_application_permission(app, "edit")

    assert_user_has_permissions %w(edit signin), app, user
  end

  test "inviting a user sets confirmed_at" do
    if user = User.find_by_email("j@1.com")
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
    refute user.persisted?
  end

  test "doesn't allow previously used password" do
    password = @user.password

    @user.password = "some v3ry s3cure passphrase"
    @user.password_confirmation = "some v3ry s3cure passphrase"
    @user.save!

    @user.password = password
    @user.password_confirmation = password

    refute @user.valid?
  end

  test "doesn't allow user to change to same password" do
    password = @user.password

    @user = User.find(@user.id)

    @user.password = password
    @user.password_confirmation = password
    refute @user.valid?
  end

  context "User status" do
    setup do
      @locked = create(:user)
      @locked.lock_access!
      @suspended = create(:user)
      @suspended.suspend("because grumble")
      @invited = User.invite!(name: "Oberyn Martell", email: "redviper@dorne.com")
      @expired = create(:user, password_changed_at: 91.days.ago)
    end

    context "filtering" do
      should "be able to filter by all statuses" do
        User::USER_STATUSES.each do |status|
          assert_not_empty User.with_status(status)
        end
      end

      should "filter suspended" do
        assert_equal [@suspended], User.with_status(User::USER_STATUS_SUSPENDED).all
      end

      should "filter invited" do
        assert_equal [@invited], User.with_status(User::USER_STATUS_INVITED).all
      end

      should "filter passphrase expired" do
        assert_equal [@expired], User.with_status(User::USER_STATUS_PASSPHRASE_EXPIRED).all
      end

      should "filter locked" do
        assert_equal [@locked], User.with_status(User::USER_STATUS_LOCKED).all
      end

      should "filter active" do
        assert_equal [@user], User.with_status(User::USER_STATUS_ACTIVE).all
      end
    end

    context "detecting" do
      should "detect suspended" do
        assert_equal "suspended", @suspended.status
      end

      should "detect invited" do
        assert_equal "invited", @invited.status
      end

      should "detect passphrase expired" do
        assert_equal "passphrase expired", @expired.status
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

    should "not return passphrase expired" do
      api_user = create(:api_user, password_changed_at: 91.days.ago)
      assert_not_equal "passphrase expired", api_user.status
    end
  end

  context "authorised applications" do
    setup do
      @user = create(:user)
      @app = create(:application)

      # authenticate access
      ::Doorkeeper::AccessToken.create(resource_owner_id: @user.id, application_id: @app.id, token: "1234")
    end

    should "include applications the user is authorised for" do
      assert_includes @user.authorised_applications, @app
    end

    should "not include applications the user is not authorised for" do
      unused_app = create(:application)
      assert_not_includes @user.authorised_applications, unused_app
    end
  end

  context ".send_reset_password_instructions" do
    context "for a suspended user" do
      should "return the user" do
        user = create(:suspended_user)
        assert_equal user, User.send_reset_password_instructions({ email: user.email })
      end

      should "notify them that reset password is disallowed and not send reset instructions" do
        user = create(:suspended_user)

        assert_enqueued_jobs 1 do
          User.send_reset_password_instructions({ email: user.email })
        end
      end
    end

    should "raise any other exception that occured" do
      User.any_instance.stubs(:send_reset_password_instructions).raises(Net::SMTPFatalError, "Inbox is full")
      user = create(:user)

      assert_raise(Net::SMTPFatalError) do
        User.send_reset_password_instructions({ email: user.email })
      end
    end
  end

  def assert_user_has_permissions(expected_permissions, application, user)
    permissions = user.permissions_for(application)
    assert_equal expected_permissions, permissions
  end
end
