require "test_helper"
require "support/policy_helpers"

class Account::PasswordsPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  should "allow logged in users to see show irrespective of their role" do
    assert permit?(build(:user), nil, :show)
  end

  should "not allow anonymous visitors to see show" do
    assert forbid?(nil, nil, :show)
  end
end
