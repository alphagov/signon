require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = FactoryGirl.create(:user)
  end

  # JSON Output

  test "sensible json output" do
    assert_equal( { 'user' => { 'email' =>  @user.email, 'name' => @user.name, 'uid' => @user.uid } }.to_json, @user.to_sensible_json )
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
