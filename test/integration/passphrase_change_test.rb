#encoding: utf-8
require 'test_helper'
require 'helpers/passphrase_support'

class PassphraseChangeTest < ActionDispatch::IntegrationTest
  include PassPhraseSupport

  context "normal user" do
    setup do
      @original_password = "some v3ry s3cure passphrase"
      @user = create(:user, email: "jane.user@example.com", password: @original_password)
      visit new_user_session_path
      signin_with(@user)
    end

    should "change passphrase if the new passphrase is secure enough" do
      change_password_to("4 totally! dzzzifferent pass-phrase")

      assert_response_contains("Your passphrase was changed successfully.")
      assert_password "4 totally! dzzzifferent pass-phrase"
    end

    should "not change the passphrase if the old one isn't provided" do
      change_password(old: "",
                      new: "some ev3n mor3 s3cure passphrase",
                      new_confirmation: "some ev3n mor3 s3cure passphrase")

      assert_response_contains("Current passphrase can't be blank")
      assert_password_unchanged
    end

    should "not change the passphrase if the old one isn't correct" do
      change_password(old: "xxxx",
                      new: "some ev3n mor3 s3cure passphrase",
                      new_confirmation: "some ev3n mor3 s3cure passphrase")

      assert_response_contains("Current passphrase is invalid")
      assert_password_unchanged
    end

    should "not change the passphrase if the new one and the confirmation don't match" do
      change_password(old: @original_password,
                      new: "some ev3n mor3 s3cure passphrase",
                      new_confirmation: "ev3n mor3 s3cure")

      assert_response_contains("confirmation doesn't match")
      assert_password_unchanged
    end

    should "not change the passphrase if the new one is too short" do
      change_password_to("shore")

      assert_response_contains("too short")
      assert_password_unchanged
    end

    should "not change the passphrase if the new one is too weak" do
      change_password_to("Zyzzogeton")

      assert_response_contains("not strong enough")
      assert_password_unchanged
    end

    should "provide the user with feedback as they pick a new password" do
      use_javascript_driver

      signout
      visit root_path
      signin_with(@user)

      click_link "Change your email or passphrase"
      fill_in "Current passphrase", with: @original_password

      refute_response_contains("The new passphrase")

      fill_in "New passphrase", with: "abcde"
      assert_response_contains("Your new passphrase")
      assert_response_contains("Must be at least 10 characters")

      fill_in "New passphrase", with: "very weak password"
      refute_response_contains("Must be at least 10 characters")
      assert_response_contains("Must be more complex")

      fill_in "New passphrase", with: "janeuser11"
      assert_response_contains("Shouldn’t include part or all of your email address")
      assert_response_contains("Must be more complex")

      fill_in "New passphrase", with: "stronger password purple monkey dishwasher"
      refute_response_contains("Must be more complex")
      refute_response_contains("Your new passphrase")

      fill_in "Confirm new passphrase", with: "stronger password"
      assert_response_contains("confirmation must match the password")
      fill_in "Confirm new passphrase", with: "stronger password purple monkey dishwasher"
      refute_response_contains("confirmation must match the password")

      click_button "Change passphrase"

      assert_response_contains("Your passphrase was changed successfully")
    end

    should "not accept the last used password as the new password" do
      change_password_to(@original_password)

      assert_response_contains "Passphrase was used previously. Please choose a different one."
    end

    should "not accept a recently-used password as the new password" do
      change_password_to("a 5tr0ng p4ssphrase")
      assert_response_contains("Your passphrase was changed successfully")

      change_password_to(@original_password)
      assert_response_contains "Passphrase was used previously. Please choose a different one."
    end
  end

  context "admin user" do
    should "change passphrase if the new passphrase is secure enough" do
      original_password = "some v3ry s3cure passphrase"
      @user = create(:admin_user, password: original_password)
      visit new_user_session_path
      signin_with(@user)

      change_password_to("4 totally! dzzzifferent pass-phrase")

      assert_response_contains("Your passphrase was changed successfully.")
      assert_password "4 totally! dzzzifferent pass-phrase"
    end
  end

  private
  def change_password_to(new_password)
    change_password(old: @user.password,
                    new: new_password,
                    new_confirmation: new_password)
  end

  def assert_password_unchanged
    assert_password(@original_password)
  end

  def assert_password(passphrase)
    @user.reload
    assert @user.valid_password?(passphrase)
  end
end
