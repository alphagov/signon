require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = FactoryGirl.create(:user)
  end

  # JSON Output

  test "sensible json output" do
    assert_equal( { 'email' =>  @user.email }.to_json, @user.to_sensible_json )
  end
end
