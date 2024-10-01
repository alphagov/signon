require "test_helper"

class TwoStepVerificationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  context "setting a 2SV code" do
    setup do
      @new_secret = ROTP::Base32.random_base32
      @original_secret = ROTP::Base32.random_base32
      ROTP::Base32.stubs(random_base32: @new_secret)
    end

    context "signed in with an existing 2SV setup" do
      setup do
        @user = create(:user, email: "jane.user@example.com", otp_secret_key: @original_secret)
        visit new_user_session_path
        signin_with(@user)
        visit two_step_verification_path
      end

      should "show the TOTP secret and a warning" do
        assert_response_contains "Enter this code when asked: #{@new_secret}"
        assert_response_contains "Setting up a new phone will replace your existing one. You will only be able to sign in with your new phone."
      end

      should "reject an invalid code, reuse the secret and log the rejection" do
        fill_in "code", with: "abcdef"
        click_button "Finish replacing your phone"

        assert_response_contains "Sorry that code didn’t work. Please try again."
        assert_response_contains "Enter this code when asked: #{@new_secret}"
        assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_CHANGE_FAILED.id, uid: @user.uid).count
      end

      should "accept a valid code, persist the secret and log the event" do
        perform_enqueued_jobs do
          enter_2sv_code(@new_secret)
          click_button "Finish replacing your phone"

          assert_response_contains "2-step verification phone changed successfully"
          assert_equal @new_secret, @user.reload.otp_secret_key
          assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_CHANGED.id, uid: @user.uid).count

          assert last_email
          assert "Your 2-step verification phone has been changed", last_email.subject
        end
      end

      should "redirect to account page on success" do
        enter_2sv_code(@new_secret)
        click_button "Finish replacing your phone"

        assert_current_url account_path
        assert_response_contains "2-step verification phone changed successfully"
      end

      should "require the code again on next login" do
        enter_2sv_code(@new_secret)
        click_button "Finish replacing your phone"

        click_link "Sign out"

        assert signin_with(@user)
      end
    end

    context "for a user without an existing 2SV setup" do
      setup do
        @user = create(:user, email: "jane.user@example.com")
        visit root_path
        signin_with(@user)
      end

      context "when visiting the 2SV setup page" do
        setup do
          visit two_step_verification_path
        end

        should "show the TOTP secret" do
          assert_response_contains "Enter this code when asked: #{@new_secret}"
        end

        should "reject an invalid code, reuse the secret and log the rejection" do
          fill_in "code", with: "abcdef"
          click_button "Finish set up"

          assert_response_contains "Sorry that code didn’t work. Please try again."
          assert_response_contains "Enter this code when asked: #{@new_secret}"
          assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_ENABLE_FAILED.id, uid: @user.uid).count
        end

        should "accept a valid code, persist the secret, log an event and notify by email" do
          success = "2-step verification set up".freeze
          perform_enqueued_jobs do
            enter_2sv_code(@new_secret)
            click_button "Finish set up"

            assert_response_contains success
            assert_equal @new_secret, @user.reload.otp_secret_key
            assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_ENABLED.id, uid: @user.uid).count

            assert last_email
            assert success, last_email.subject
          end
        end

        should "accept a valid code from a device which has a small time lag" do
          old_code = Timecop.freeze(29.seconds.ago) { ROTP::TOTP.new(@new_secret).now }

          Timecop.freeze do
            fill_in "code", with: old_code
            click_button "Finish set up"
          end

          assert_response_contains "2-step verification set up"
        end
      end

      context "when visiting the 2SV sign-in page" do
        setup do
          visit new_two_step_verification_session_path
        end

        should "redirect to home page" do
          assert_response_contains "Make your account more secure"
        end
      end
    end

    context "for a user with a 2sv exemption reason" do
      setup do
        @user = create(:two_step_exempted_user, email: "jane.user@example.com")
        visit root_path
        signin_with(@user)
        visit two_step_verification_path
      end

      should "show the TOTP secret" do
        assert_response_contains "Enter this code when asked: #{@new_secret}"
      end

      should "accept a valid code, persist the secret, log an event and notify by email, and remove the exemption reason and expiry date" do
        success = "2-step verification set up".freeze
        perform_enqueued_jobs do
          enter_2sv_code(@new_secret)
          click_button "Finish set up"

          assert_response_contains success
          assert_nil @user.reload.reason_for_2sv_exemption
          assert_nil @user.reload.expiry_date_for_2sv_exemption
          assert_equal @new_secret, @user.reload.otp_secret_key
          assert_equal 1, EventLog.where(event_id: EventLog::TWO_STEP_ENABLED.id, uid: @user.uid).count

          assert last_email
          assert success, last_email.subject
        end
      end

      should "require the code again on next login" do
        enter_2sv_code(@new_secret)
        click_button "Finish set up"

        click_link "Sign out"

        assert signin_with(@user)
      end
    end
  end
end
