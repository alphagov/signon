require "test_helper"

class PermissionUpdaterTest < ActiveSupport::TestCase
  context "status" do
    should "return 'OK' when no tokens are expiring" do
      check = Healthcheck::ApiTokens.new
      assert_equal :ok, check.status
    end

    should "return 'OK' when tokens for @<env>.publishing.service.gov.uk are expiring" do
      user = create(:api_user, email: "#{random_str}@#{ENV['GOVUK_ENVIRONMENT']}.publishing.service.gov.uk")

      make_api_user_token(
        expires_in: Healthcheck::ApiTokens::WARNING_THRESHOLD,
        user:,
      )
      check = Healthcheck::ApiTokens.new
      assert_equal :ok, check.status
    end

    should "return 'OK' when EKS tokens are expiring" do
      user = create(:api_user, name: "Publisher [EKS]")

      make_api_user_token(
        expires_in: Healthcheck::ApiTokens::WARNING_THRESHOLD,
        user:,
      )
      check = Healthcheck::ApiTokens.new
      assert_equal :ok, check.status
    end

    should "return 'WARNING' when a token is getting old" do
      make_api_user_token(expires_in: Healthcheck::ApiTokens::WARNING_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_equal :warning, check.status
    end

    should "return 'CRITICAL' when a token is almost expired" do
      make_api_user_token(expires_in: Healthcheck::ApiTokens::CRITICAL_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_equal :critical, check.status
    end

    should "return 'CRITICAL' even when if we have a 'WARNING'" do
      make_api_user_token(expires_in: Healthcheck::ApiTokens::WARNING_THRESHOLD)
      make_api_user_token(expires_in: Healthcheck::ApiTokens::CRITICAL_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_equal :critical, check.status
    end

    should "return 'OK' when the tokens are for normal users" do
      make_normal_user_token(expires_in: Healthcheck::ApiTokens::CRITICAL_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_equal :ok, check.status
    end
  end

  context "details" do
    should "return which tokens are causing the check to fail" do
      user = create :api_user, email: "#{random_str}@digital.cabinet-office.gov.uk"

      expiring_token = make_api_user_token(
        expires_in: Healthcheck::ApiTokens::WARNING_THRESHOLD,
        user:,
      )

      message = "#{user.name} token for #{expiring_token.application.name} " \
        "expires in #{Healthcheck::ApiTokens::WARNING_THRESHOLD / 1.day.to_i} days"

      check = Healthcheck::ApiTokens.new
      assert_match(message, check.message)
    end

    should "not return expiring token details for normal users" do
      make_normal_user_token(expires_in: Healthcheck::ApiTokens::CRITICAL_THRESHOLD)
      check = Healthcheck::ApiTokens.new
      assert_match("", check.message)
    end

    should "cope when the token has already expired" do
      make_api_user_token(expires_in: -1.hour.to_i)
      check = Healthcheck::ApiTokens.new
      assert_match("expires in -1 days", check.message)
    end
  end

  def random_str
    SecureRandom.hex(5)
  end

  def make_api_user_token(expires_in:, user: nil)
    user ||= create :api_user, email: "#{random_str}@digital.cabinet-office.gov.uk"
    create :access_token, resource_owner_id: user.id, expires_in: expires_in - 1
  end

  def make_normal_user_token(expires_in:)
    user ||= create :user
    create :access_token, resource_owner_id: user.id, expires_in: expires_in - 1
  end
end
