require "test_helper"

class Doorkeeper::AccessTokenTest < ActiveSupport::TestCase
  context ".not_revoked" do
    should "return tokens that have not been revoked" do
      revoked_token = create(:access_token, revoked_at: Time.current)
      non_revoked_token = create(:access_token, revoked_at: nil)

      tokens = Doorkeeper::AccessToken.not_revoked

      assert_not_includes tokens, revoked_token
      assert_includes tokens, non_revoked_token
    end
  end

  context ".expires_after" do
    should "return tokens expiring after specified time" do
      token_expiring_in_1_week = create(:access_token, expires_in: 1.week)
      token_expiring_in_3_weeks = create(:access_token, expires_in: 3.weeks)

      tokens = Doorkeeper::AccessToken.expires_after(2.weeks.from_now)

      assert_not_includes tokens, token_expiring_in_1_week
      assert_includes tokens, token_expiring_in_3_weeks
    end
  end
end
