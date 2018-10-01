require 'test_helper'
require 'helpers/password_support'

class PasswordResetTest < ActionDispatch::IntegrationTest
  include PasswordSupport
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

  should "not give away whether an email exists in the system or not" do
    trigger_reset_for("non-existent-email@example.com")

    assert !page.has_content?("Email not found"), page.body
    assert_response_contains(BLANKET_RESET_MESSAGE)
  end

  should "work for a partially signed-in user with an expired password" do
    perform_enqueued_jobs do
      user = create(:user, password_changed_at: 91.days.ago)

      trigger_reset_for(user.email)

      visit root_path
      signin_with(email: user.email, password: user.password)

      open_email(user.email)
      assert current_email
      assert_equal "noreply-signon-development@digital.cabinet-office.gov.uk", current_email.from[0]
      assert_nil last_email.reply_to[0]
      assert_equal "Reset password instructions", current_email.subject

      # partially signed-in user should be able to reset password using link in reset password instructions
      complete_password_reset(current_email, new_password: "some v3ry s3cure password")
      assert_response_contains("Your password was changed successfully")
    end
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

      assert_response_contains("That password reset didn’t work.")
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

  should "be accessible from the change password screen by a partially signed-in user" do
    user = create(:user, password_changed_at: 91.days.ago)

    visit root_path
    signin_with(email: user.email, password: user.password)

    # partially signed-in user should be able to reset password using link in reset password instructions
    click_link 'Forgot your password?'
    assert_response_contains("Request a password reset")
  end

  should "show error messages when password reset doesn't work" do
    perform_enqueued_jobs do
      user = create(:user)
      trigger_reset_for(user.email)

      open_email(user.email)

      current_email.click_link("Change my password")
      fill_in "New password", with: "A Password"
      fill_in "Confirm new password", with: "Not That Password"
      click_button "Change password"

      assert_response_contains("Password confirmation doesn't match")
    end
  end
end
