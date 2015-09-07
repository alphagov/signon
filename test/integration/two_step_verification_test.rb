#encoding: utf-8
require 'test_helper'
require 'helpers/passphrase_support'

class TwoStepVerificationTest < ActionDispatch::IntegrationTest
  context "setting up" do
    context "with an existing 2SV setup" do
      setup do
        @user = create(:user, email: "jane.user@example.com", otp_secret_key: ROTP::Base32.random_base32)
        visit new_user_session_path
        signin_with_2sv(@user)
        visit new_two_factor_authentication_path
      end

      should "redirect to homepage" do
        assert_response_contains "Two Step Verification is already set up"
        assert_response_contains "Welcome to GOV.UK"
      end
    end

    context "without an existing 2SV setup" do
      setup do
        @user = create(:user, email: "jane.user@example.com")
        visit new_user_session_path
        signin(@user)
        @secret = ROTP::Base32.random_base32
        ROTP::Base32.stubs(random_base32: @secret)
        visit new_two_factor_authentication_path
      end

      should "show the TOTP secret" do
        assert_response_contains "Enter the code manually: #{@secret}"
      end

      context "with an incorrect code entered" do
        setup do
          fill_in "code", with: "abcdef"
          click_button "submit_code"
        end

        should "reject the code" do
          assert_response_contains "Invalid Two Step Verification code. Perhaps you entered it incorrectly?"
        end

        should "show the same secret" do
          assert_response_contains "Enter the code manually: #{@secret}"
        end
      end

      context "with the correct code entered" do
        setup do
          Timecop.freeze do
            fill_in "code", with: ROTP::TOTP.new(@secret).now
            click_button "submit_code"
          end
        end

        should "accept the code" do
          assert_response_contains "Two Step Verification set up"
        end

        should "persist the confirmed secret" do
          assert_equal @secret, @user.reload.otp_secret_key
        end
      end
    end
  end
end
