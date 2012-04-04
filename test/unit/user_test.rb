require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = FactoryGirl.create(:user)
  end

  # JSON Output

  test "sensible json output" do
    assert_equal( { 'email' =>  @user.email }.to_json, @user.to_sensible_json )
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
end
