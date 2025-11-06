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

  context ".expires_before" do
    should "return tokens expiring before specified time" do
      token_expiring_in_1_week = create(:access_token, expires_in: 1.week)
      token_expiring_in_3_weeks = create(:access_token, expires_in: 3.weeks)

      tokens = Doorkeeper::AccessToken.expires_before(2.weeks.from_now)

      assert_not_includes tokens, token_expiring_in_3_weeks
      assert_includes tokens, token_expiring_in_1_week
    end
  end

  context ".expired" do
    should "return tokens that have expired" do
      token_expiring_1_day_ago = create(:access_token, expires_in: -1.day)
      token_expiring_in_1_day = create(:access_token, expires_in: 1.day)

      tokens = Doorkeeper::AccessToken.expired

      assert_includes tokens, token_expiring_1_day_ago
      assert_not_includes tokens, token_expiring_in_1_day
    end
  end

  context ".ordered_by_expires_at" do
    should "return tokens ordered by expiry time" do
      token_expiring_in_2_weeks = create(:access_token, expires_in: 2.weeks)
      token_expiring_in_1_week = create(:access_token, expires_in: 1.week)

      tokens = Doorkeeper::AccessToken.ordered_by_expires_at

      assert_equal [token_expiring_in_1_week, token_expiring_in_2_weeks], tokens
    end
  end

  context ".ordered_by_application_name" do
    should "return tokens ordered by application name" do
      application_named_foo = create(:application, name: "Foo")
      application_named_bar = create(:application, name: "Bar")

      token_for_foo = create(:access_token, application: application_named_foo)
      token_for_bar = create(:access_token, application: application_named_bar)

      tokens = Doorkeeper::AccessToken.ordered_by_application_name

      assert_equal [token_for_bar, token_for_foo], tokens
    end
  end
end
