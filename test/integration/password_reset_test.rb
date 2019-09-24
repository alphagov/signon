require "test_helper"
require "support/password_helpers"

class PasswordResetTest < ActionDispatch::IntegrationTest
  include PasswordHelpers
  include ActiveJob::TestHelper

  BLANKET_RESET_MESSAGE = "If your email address is recognised, you’ll receive an email with instructions about how to reset your password.".freeze

  should "email password reset instructions and allow the user to set a new one" do
    perform_enqueued_jobs do
      user = create(:user)
      new_password = "some v3ry s3cure password"

      trigger_reset_for(user.email)
      assert_response_contains(BLANKET_RESET_MESSAGE)

      open_email(user.email)
      assert current_email
      assert_equal "Reset password instructions", current_email.subject

      complete_password_reset(current_email, new_password: new_password)
      assert_response_contains("Your password was changed successfully")

      user.reload
      assert user.valid_password?(new_password)
    end
  end

  should "not allow password reset for unaccepted invitations" do
    perform_enqueued_jobs do
      user = create(:user, invitation_sent_at: Time.zone.now, invitation_accepted_at: nil)
      trigger_reset_for(user.email)
      assert_response_contains(BLANKET_RESET_MESSAGE)

      open_email(user.email)
      assert current_email
      assert_equal "Your GOV.UK Signon development account has not been activated", current_email.subject
    end
  end

  should "not allow password reset for suspended users" do
    perform_enqueued_jobs do
      user = create(:suspended_user)
      trigger_reset_for(user.email)
      assert_response_contains(BLANKET_RESET_MESSAGE)

      open_email(user.email)
      assert current_email
      assert_equal "Your GOV.UK Signon development account has been suspended", current_email.subject
    end
  end

  should "not give away whether an email exists in the system or not" do
    trigger_reset_for("non-existent-email@example.com")

    assert !page.has_content?("Email not found"), page.body
    assert_response_contains(BLANKET_RESET_MESSAGE)
  end

  should "not allow a reset link to be used more than once" do
    perform_enqueued_jobs do
      user = create(:user)
      new_password = "some v3ry s3cure password"

      trigger_reset_for(user.email)

      open_email(user.email)
      assert current_email
      assert_equal "Reset password instructions", current_email.subject

      complete_password_reset(current_email, new_password: new_password)
      assert_response_contains("Your password was changed successfully")

      signout

      current_email.click_link("Change my password")

      assert_response_contains("Sorry, this link doesn't work")
    end
  end

  should "not be broken by virus-scanners that follow links in emails" do
    # Some users have virus-scanning systems that follow links in emails to
    # check for anything malicious.  This was breaking this flow because the
    # token was being reset the first time the page was accessed (introduced in
    # a044b79).

    perform_enqueued_jobs do
      user = create(:user)
      new_password = "some v3ry s3cure password"

      trigger_reset_for(user.email)

      open_email(user.email)
      assert current_email
      assert_equal "Reset password instructions", current_email.subject

      # simulate something following the link in the email.
      current_email.click_link("Change my password")

      complete_password_reset(current_email, new_password: new_password)
      assert_response_contains("Your password was changed successfully")
    end
  end

  should "show error messages when password reset doesn't work" do
    perform_enqueued_jobs do
      user = create(:user)
      trigger_reset_for(user.email)

      open_email(user.email)

      current_email.click_link("Change my password")
      fill_in "New password", with: "A Password"
      fill_in "Confirm new password", with: "Not That Password"
      click_button "Save password"

      assert_response_contains("Password confirmation doesn't match")
    end
  end
end
