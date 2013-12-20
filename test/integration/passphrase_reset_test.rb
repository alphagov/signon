require 'test_helper'
require 'helpers/passphrase_support'
 
class PassphraseResetTest < ActionDispatch::IntegrationTest
  include PassPhraseSupport

  BLANKET_RESET_MESSAGE = "If your e-mail exists on our database, you will receive a passphrase recovery link on your e-mail"

  should "reset a user's password and let them set a new one" do
    user = create(:user)
    new_password = "some v3ry s3cure passphrase"

    trigger_reset_for(user.email)
    assert_response_contains(BLANKET_RESET_MESSAGE)
    
    user.reload
    complete_password_reset(reset_password_token: user.reset_password_token, new_password: new_password)

    assert_response_contains("Your passphrase was changed successfully")
    user.reload
    assert user.valid_password?(new_password)
  end

  should "not give away whether an email exists in the system or not" do
    trigger_reset_for("non-existent-email@example.com")

    assert !page.has_content?("Email not found"), page.body
    assert_response_contains(BLANKET_RESET_MESSAGE)
  end

  should "not give away whether an email is on the SES blacklist" do
    user = create(:user)
    given_email_is_on_ses_blacklist

    trigger_reset_for(user.email)

    assert !page.has_content?("Email not found"), page.body
    assert_response_contains(BLANKET_RESET_MESSAGE)
  end
end
