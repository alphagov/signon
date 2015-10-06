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
        visit new_two_step_verification_path
      end

      should "redirect to homepage" do
        assert_response_contains "2-step verification is already set up"
        assert_response_contains "Welcome to GOV.UK"
      end
    end

    context "without an existing 2SV setup" do
      setup do
        @user = create(:admin_user, email: "jane.user@example.com", require_2sv: true)
        visit users_path
        signin(@user)
        @secret = ROTP::Base32.random_base32
        ROTP::Base32.stubs(random_base32: @secret)
        visit new_two_step_verification_path
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
          assert_response_contains "Sorry that code didn’t work. Please try again."
        end

        should "show the same secret" do
          assert_response_contains "Enter the code manually: #{@secret}"
        end

        should "log the failure in the event log" do
          assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_ENABLE_FAILED, uid: @user.uid).count
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
          assert_response_contains "2-step verification set up"
        end

        should "persist the confirmed secret" do
          assert_equal @secret, @user.reload.otp_secret_key
        end

        should "log the set up in the event log" do
          assert_equal 1, EventLog.where(event: EventLog::TWO_STEP_ENABLED, uid: @user.uid).count
        end

        should "reset the `require_2sv` flag" do
          refute @user.reload.require_2sv?
        end

        should "direct them back to where they were originally headed" do
          assert_equal users_path, current_path
        end
      end
    end
  end
end
