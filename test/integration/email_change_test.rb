require 'test_helper'
require 'helpers/user_account_operations'
 
class EmailChangeTest < ActionDispatch::IntegrationTest
  include UserAccountOperations

  context "by an admin" do
    setup do
      @admin = create(:user, role: "admin")
    end

    context "for an active user" do
      should "trigger a confirmation email to the user" do
        user = create(:user)

        visit new_user_session_path
        signin(@admin)
        admin_changes_email_address(user: user, new_email: "new@email.com")

        assert_equal "new@email.com", last_email.to[0]
        assert_equal 'Confirm your email change', last_email.subject

        user.reload
        confirm_email_change(confirmation_token: user.confirmation_token,
                             password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z")
        assert_response_contains("Your account was successfully confirmed. You are now signed in.")
      end
    end

    context "for a user who hasn't accepted their invite yet" do
      should "resend a confirmation email" do
        user = User.invite!(name: "Jim", email: "jim@web.com")

        visit new_user_session_path
        signin(@admin)
        admin_changes_email_address(user: user, new_email: "new@email.com")

        assert_equal "new@email.com", last_email.to[0]
        assert_equal 'Please confirm your account', last_email.subject

        user.reload
        accept_invitation(invitation_token: user.invitation_token,
                          password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z")
        assert_response_contains("Your passphrase was set successfully. You are now signed in.")
      end
    end

    context "when the change was made in error" do
      should "be cancellable" do
        use_javascript_driver

        user = create(:user_with_pending_email_change)
        original_email = user.email

        visit new_user_session_path
        signin(@admin)
        visit edit_admin_user_path(user)
        click_link "Cancel email change"

        user.reload
        signout
        visit user_confirmation_path(confirmation_token: user.confirmation_token)
        assert_response_contains("Couldn't confirm email change. Please contact support to request a new confirmation email.")
        assert_equal original_email, user.email
      end
    end
  end

  context "by a user themselves" do
    setup do
      @user = create(:user, email: "original@email.com")
    end

    should "trigger a confirmation email to the user" do
      visit new_user_session_path
      signin(@user)

      visit edit_user_path(@user)
      fill_in "Email", with: "new@email.com"
      click_button "Change email"

      assert_equal "new@email.com", last_email.to[0]
      assert_equal 'Confirm your email change', last_email.subject
    end

    should "be cancellable" do
      use_javascript_driver

      visit new_user_session_path
      signin(@user)

      @user.update_column(:unconfirmed_email, "new@email.com")

      visit edit_user_path(@user)
      click_link "Cancel email change"

      @user.reload
      signout
      visit user_confirmation_path(confirmation_token: @user.confirmation_token)
      assert_response_contains("Couldn't confirm email change. Please contact support to request a new confirmation email.")
      assert_equal "original@email.com", @user.email
    end
  end
end
