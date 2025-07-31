require "test_helper"

class TwoStepVerificationHelperTest < ActionView::TestCase
  setup do
    @user = build(:user)
    @secret = ROTP::Base32.random_base32
    ROTP::Base32.stubs(random_base32: @secret)
  end

  context "otp_secret_key_uri(user: @user, otp_secret_key: @secret)" do
    should "include the secret key uppercased" do
      assert_match %r{#{@secret.upcase}}, otp_secret_key_uri(user: @user, otp_secret_key: @secret)
    end

    should "include the environment titleised" do
      assert_match %r{issuer=Development%20.*%20Signon}, otp_secret_key_uri(user: @user, otp_secret_key: @secret)
    end

    context "in production" do
      setup do
        GovukEnvironment.stubs(:current).returns("production")
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

  context "qr_code_svg(user:, otp_secret_key:)" do
    should "should return an svg" do
      assert_match %r{<svg.*>.*</svg>}, qr_code_svg(user: @user, otp_secret_key: @secret)
    end
  end

  context "two_factor_code_input" do
    attr_reader :component_name

    setup do
      @component_name = "govuk_publishing_components/components/input"
    end

    should "render the input component" do
      GovukPublishingComponents
        .expects(:render)
        .with(component_name, anything)

      two_factor_code_input
    end

    should "pass additional arguments to the component renderer" do
      GovukPublishingComponents
        .expects(:render)
        .with(component_name, has_entry(additional: "argument"))

      two_factor_code_input(additional: "argument")
    end
  end
end
