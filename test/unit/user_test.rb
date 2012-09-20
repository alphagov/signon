require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = FactoryGirl.create(:user)
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
          "app1" => ["signin", "coughing"]
        }
      }
    }
    assert_equal(expected, JSON.parse(@user.to_sensible_json(app1)) )
  end

  # Attribute protection

  test "the is_admin flag has to be specifically assigned" do
    u = User.new(name: 'Bad User', is_admin: true)
    assert ! u.is_admin?

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

  test "it requires a reason for suspension to suspend a user" do
    u = FactoryGirl.create(:user)
    u.suspended_at = 1.minute.ago
    assert ! u.valid?
    assert_not_empty u.errors[:reason_for_suspension]
  end
end
