require 'test_helper'

class PermissionUpdaterTest < ActiveSupport::TestCase
  context "status" do
    should "return 'OK' when no tokens are expiring" do
      check = Healthcheck::ApiTokens.new
      assert_equal GovukHealthcheck::OK, check.status
    end

    should "return 'WARNING' when a token is getting old" do
      make_api_user_token(expires_in: Healthcheck::ApiTokens::WARNING_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_equal GovukHealthcheck::WARNING, check.status
    end

    should "return 'CRITICAL' when a token is almost expired" do
      make_api_user_token(expires_in: Healthcheck::ApiTokens::CRITICAL_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_equal GovukHealthcheck::CRITICAL, check.status
    end

    should "return 'CRITICAL' even when if we have a 'WARNING'" do
      make_api_user_token(expires_in: Healthcheck::ApiTokens::WARNING_THRESHOLD)
      make_api_user_token(expires_in: Healthcheck::ApiTokens::CRITICAL_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_equal GovukHealthcheck::CRITICAL, check.status
    end

    should "return 'OK' when the tokens are for normal users" do
      make_normal_user_token(expires_in: Healthcheck::ApiTokens::CRITICAL_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_equal GovukHealthcheck::OK, check.status
    end
  end

  context "details" do
    should "return which tokens are causing the check to fail" do
      warning_user = create :api_user
      critical_user = create :api_user

      warning_token = make_api_user_token(
        expires_in: Healthcheck::ApiTokens::WARNING_THRESHOLD,
        user: warning_user,
      )

      critical_token = make_api_user_token(
        expires_in: Healthcheck::ApiTokens::CRITICAL_THRESHOLD,
        user: critical_user,
      )

      check = Healthcheck::ApiTokens.new

      assert_equal(
        {
          warnings: [[warning_user.name, warning_token.application.name]],
          criticals: [[critical_user.name, critical_token.application.name]],
        },
        check.details
      )
    end

    should "not return expiring token details for normal users" do
      make_normal_user_token(expires_in: Healthcheck::ApiTokens::CRITICAL_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_equal({ warnings: [], criticals: [] }, check.details)
    end
  end

  def make_api_user_token(expires_in:, user: nil)
    user ||= create :api_user
    create :access_token, resource_owner_id: user.id, expires_in: expires_in - 1
  end

  def make_normal_user_token(expires_in:)
    user ||= create :user
    create :access_token, resource_owner_id: user.id, expires_in: expires_in - 1
  end
end
