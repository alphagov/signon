require "test_helper"

class TwoStepVerificationHelperTest < ActionView::TestCase
  context "otp_secret_key_uri(user: @user, otp_secret_key: @secret)" do
    setup do
      @user = build(:user)
      @secret = ROTP::Base32.random_base32
      ROTP::Base32.stubs(random_base32: @secret)
    end

    should "include the secret key uppercased" do
      assert_match %r{#{@secret.upcase}}, otp_secret_key_uri(user: @user, otp_secret_key: @secret)
    end

    should "include the environment titleised" do
      assert_match %r{issuer=Development%20.*%20Signon}, otp_secret_key_uri(user: @user, otp_secret_key: @secret)
    end

    context "in production" do
      setup do
        @old_instance_name = Rails.application.config.instance_name
        Rails.application.config.instance_name = nil
      end

      teardown do
        Rails.application.config.instance_name = @old_instance_name
      end

      should "not include the environment name" do
        assert_match %r{issuer=.*%20Signon}, otp_secret_key_uri(user: @user, otp_secret_key: @secret)
        assert_no_match %r{issuer=Development%20.*%20Signon}, otp_secret_key_uri(user: @user, otp_secret_key: @secret)
      end
    end

    context "when different issuer name is provided within the localisation data" do
      should "use the value provided by i18n" do
        I18n.stubs(t: "issuer test")
        assert_match %r{issuer=Development%20issuer%20test}, otp_secret_key_uri(user: @user, otp_secret_key: @secret)
      end
    end

    should "include the user's email" do
      assert_match %r{#{@user.email}}, otp_secret_key_uri(user: @user, otp_secret_key: @secret)
    end
  end
end
