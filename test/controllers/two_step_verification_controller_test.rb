require 'test_helper'

class TwoStepVerificationControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @controller = Devise::TwoStepVerificationController.new

    @user = create(:user)
    sign_in @user
  end

  context "otp_secret_key_uri" do
    setup do
      @secret = ROTP::Base32.random_base32
      ROTP::Base32.stubs(random_base32: @secret)

      get :new
    end

    should "include the secret key uppercased" do
      assert_match %r{#{@secret.upcase}}, @controller.otp_secret_key_uri
    end

    should "include the environment titleised" do
      assert_match %r{Development%20GOV.UK}, @controller.otp_secret_key_uri
    end

    should "include the user's email" do
      assert_match %r{#{@user.email}}, @controller.otp_secret_key_uri
    end
  end
end
