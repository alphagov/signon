require "test_helper"
class ApiUserTest < ActiveSupport::TestCase
  should "not be valid if require 2sv is set to true" do
    user = build(:api_user, require_2sv: true)
    assert_not user.valid?
  end

  should "be valid if require 2sv is set to false" do
    user = build(:api_user, require_2sv: false)
    assert user.valid?
  end

  should "not be valid if a reason for 2sv exemption exists" do
    user = build(:api_user, reason_for_2sv_exemption: "some reason")
    assert_not user.valid?
  end

  should "be valid if reason for 2sv exemption is nil" do
    user = build(:api_user, reason_for_2sv_exemption: nil)
    assert user.valid?
  end
end
