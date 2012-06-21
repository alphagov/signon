require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = FactoryGirl.create(:user)
  end

  # We need this as a stepping stone until we record real permissions
  test "new users should get a special 'everything' permission" do
    # everything_app = ::Doorkeeper::Application.create!(name: "Everything", uid: "not-a-real-app", secret: "does-not-have-a-secret", redirect_uri: "http://not-a-domain.com")
    user = FactoryGirl.create(:user)
    permission = user.permissions.first
    assert_equal "Everything", permission.application.name
    assert_equal ["signin"], permission.permissions
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
        "permissions" => {
          "app1" => ["signin", "coughing"],
          "Everything" => ["signin"]
        }
      }
    }
    assert_equal(expected, JSON.parse(@user.to_sensible_json) )
  end

  # Gravatar URLs

  test "gravatar url should be generated" do
    assert_equal "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(@user.email)}", @user.gravatar_url
  end

  test "differently sized gravatar url should be generatable" do
    assert_equal "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(@user.email)}?s=128", @user.gravatar_url(:s => 128)
  end

  test "secure gravatar urls should be generatable" do
    assert_equal "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(@user.email)}", @user.gravatar_url(:ssl => true)
  end

  # Attribute protection

  test "the is_admin flag has to be specifically assigned" do
    u = User.new(name: 'Bad User', is_admin: true)
    refute u.is_admin?

    u.is_admin = true
    assert u.is_admin?
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

end
