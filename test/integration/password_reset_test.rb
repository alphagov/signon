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
      assert_equal I18n.t("devise.mailer.reset_password_instructions.subject"), current_email.subject

      complete_password_reset(current_email, new_password:)
      assert_response_contains("Your password was changed successfully")

      user.reload
      assert user.valid_password?(new_password)
    end
  end

  should "not allow password reset for unaccepted invitations" do
    perform_enqueued_jobs do
      user = create(:user, invitation_sent_at: Time.current, invitation_accepted_at: nil)
      trigger_reset_for(user.email)
      assert_response_contains(BLANKET_RESET_MESSAGE)

      open_email(user.email)
      assert current_email
      assert_equal "Cannot reset GOV.UK password on inactive Signon GOV.UK test account", current_email.subject
    end
  end

  should "not allow password reset for suspended users" do
    perform_enqueued_jobs do
      user = create(:suspended_user)
      trigger_reset_for(user.email)
      assert_response_contains(BLANKET_RESET_MESSAGE)

      open_email(user.email)
      assert current_email
      assert_equal "Cannot reset password on suspended Signon GOV.UK test account", current_email.subject
    end
  end

  should "not give away whether an email exists in the system or not" do
    trigger_reset_for("non-existent-email@example.com")

    assert_not page.has_content?("Email not found"), page.body
    assert_response_contains(BLANKET_RESET_MESSAGE)
  end

  should "not allow a reset link to be used more than once" do
    perform_enqueued_jobs do
      user = create(:user)
      new_password = "some v3ry s3cure password"

      trigger_reset_for(user.email)

      open_email(user.email)
      assert current_email
      assert_equal I18n.t("devise.mailer.reset_password_instructions.subject"), current_email.subject

      complete_password_reset(current_email, new_password:)
      assert_response_contains("Your password was changed successfully")

      signout

      visit_password_reset_url_in(current_email)

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
      assert_equal I18n.t("devise.mailer.reset_password_instructions.subject"), current_email.subject

      # simulate something following the link in the email.
      visit_password_reset_url_in(current_email)

      complete_password_reset(current_email, new_password:)
      assert_response_contains("Your password was changed successfully")
    end
  end

  should "show error messages when password reset doesn't work" do
    perform_enqueued_jobs do
      user = create(:user)
      trigger_reset_for(user.email)

      open_email(user.email)

      visit_password_reset_url_in(current_email)
      fill_in "New password", with: "A Password"
      fill_in "Confirm new password", with: "Not That Password"
      click_button "Save password"

      assert_response_contains("Password confirmation doesn't match")
    end
  end

  should "return a 429 response if too many requests are made" do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    user = create(:user)
    100.times { trigger_reset_for(user.email) }
    assert_response_contains("Too many requests.")

    Rack::Attack.enabled = false
  end
end
