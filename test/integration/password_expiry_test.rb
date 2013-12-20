require 'test_helper'
require 'helpers/passphrase_support'
 
class PassphraseExpiryTest < ActionDispatch::IntegrationTest
  include PassPhraseSupport

  PROMPT_TO_CHANGE_PASSWORD = "Your passphrase has expired. Please choose a new passphrase"

  setup do
    @user = create(:user, password_changed_at: 91.days.ago)
    @new_password = "some 3v3n more s3cure passphrase"
  end

  context "(which triggers 90 days after the previous password change)" do
    should "force the user to change their password" do
      visit new_user_session_path

      signin(@user)
      assert_response_contains(PROMPT_TO_CHANGE_PASSWORD)

      reset_expired_passphrase(@user.password, @new_password, @new_password)
      assert_response_contains("Your new passphrase is saved")

      assert_equal root_url, current_url
    end

    should "remember where the user was trying to get to before the password reset" do
      visit "/user/edit?arbitrary=1"

      signin(@user)
      reset_expired_passphrase(@user.password, @new_password, @new_password)

      assert_current_url "/user/edit?arbitrary=1"
    end

    should "continue prompting for a new password if the reset didn't work" do
      visit new_user_session_path
      signin(@user)

      reset_expired_passphrase("nonsense", @new_password, @new_password)

      visit new_user_session_path
      assert_response_contains(PROMPT_TO_CHANGE_PASSWORD)
    end

    should "continue prompting for a new password if the user navigates away from the password reset page" do
      visit new_user_session_path
      signin(@user)

      visit new_user_session_path
      assert_response_contains(PROMPT_TO_CHANGE_PASSWORD)
    end    
  end
end
