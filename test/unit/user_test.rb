require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "sensible json output" do
    user = FactoryGirl.create(:user)
    assert_equal( { 'email' =>  user.email }.to_json, user.to_sensible_json )
  end
end
