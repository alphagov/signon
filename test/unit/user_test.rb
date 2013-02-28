require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = FactoryGirl.create(:user)
  end

  test "email change tokens should expire" do
    @user = FactoryGirl.create(:user_with_pending_email_change, confirmation_sent_at: 15.days.ago)
    @user.confirm!
    assert_equal "needs to be confirmed within 14 days, please request a new one", @user.errors[:email][0]
  end

  # JSON Output

  test "sensible json output" do
    app1 = FactoryGirl.create(:application, name: "app1")
    FactoryGirl.create(:permission, application: app1, user: @user, permissions: ["signin", "coughing"])
    expected = {
      "user" => {
        "email" =>  @user.email,
        "name" => @user.name,
        "uid" => @user.uid,
        "permissions" => ["signin", "coughing"]
      }
    }
    assert_equal(expected, JSON.parse(@user.to_sensible_json(app1)) )
  end

  # Attribute protection

  test "the role has to be specifically assigned" do
    u = User.new(name: 'Bad User', role: "admin")
    assert_not_equal "admin", u.role

    u.role = "admin"
    assert_equal "admin", u.role
  end

  # Password Validation

  test "it requires a password to be at least 10 characters long" do
    u = FactoryGirl.build(:user, :password => "dNG.c0w5!")
    assert !u.valid?
    assert_not_empty u.errors[:password]
  end

  test "it allows very long passwords with spaces" do
    u = FactoryGirl.build(:user, :password => ("4 l0nG sT!,ng " * 10)[0..127])
    u.valid?
    assert u.valid?
    assert_empty u.errors[:password]
  end

  test "it requires a reason for suspension to suspend a user" do
    u = FactoryGirl.create(:user)
    u.suspended_at = 1.minute.ago
    assert ! u.valid?
    assert_not_empty u.errors[:reason_for_suspension]
  end

  # Password migration
  test "it migrates old passwords on sign-in" do
    password = ("4 l0nG sT!,ng " * 10)[0..127]
    old_encrypted_password = ::BCrypt::Password.create("#{password}", :cost => 10).to_s

    u = FactoryGirl.create(:user)
    u.update_column :encrypted_password, old_encrypted_password
    u.reload

    assert u.valid_legacy_password?(password), "Not recognised as valid old-style password"
    assert u.valid_password?(password), "Doesn't allow old-style password"
    u.reload

    assert_not_equal old_encrypted_password, u.encrypted_password, "Doesn't change password format"
    assert u.valid_password?(password), "Didn't recognise correct password"
  end

  test "it doesn't migrate password unless correct one given" do
    password = ("4 l0nG sT!,ng " * 10)[0..127]
    old_encrypted_password = ::BCrypt::Password.create("#{password}", :cost => 10).to_s

    u = FactoryGirl.create(:user)
    u.update_column :encrypted_password, old_encrypted_password
    u.reload

    assert ! u.valid_password?("something else")
    u.reload

    assert_equal old_encrypted_password, u.encrypted_password, "Changed passphrase"
  end

  test "can grant permissions to user application and permission name" do
    app = FactoryGirl.create(:application, name: "my_app")
    app.supported_permissions.create!(name: 'signin')
    app.supported_permissions.create!(name: 'Create publications')
    app.supported_permissions.create!(name: 'Delete publications')
    user = FactoryGirl.create(:user)

    user.grant_permission(app, "Create publications")

    assert_user_has_permissions ['Create publications'], app, user
  end

  test "granting an unsupported permission raises an error" do
    app = FactoryGirl.create(:application, name: "my_app")
    app.supported_permissions.create!(name: 'signin')
    user = FactoryGirl.create(:user)

    assert_raises UnsupportedPermissionError do
      user.grant_permission(app, "Unsupported")
    end
  end

  test "granting an already granted permission doesn't cause duplicates" do
    app = FactoryGirl.create(:application, name: "my_app")
    user = FactoryGirl.create(:user)

    user.grant_permission(app, "signin")
    user.grant_permission(app, "signin")

    assert_user_has_permissions ['signin'], app, user
  end

  def assert_user_has_permissions(expected_permissions, application, user)
    permissions_for_my_app = user.permissions.reload.find_by_application_id(application.id)
    assert_equal expected_permissions, permissions_for_my_app.permissions
  end

end
