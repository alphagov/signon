require 'test_helper'
 
class EmailChangeTest < ActionDispatch::IntegrationTest
  context "by an admin" do
    context "for an active user" do
      should "trigger a confirmation email to the user" do
        admin = create(:user, role: "admin")
        another_user = create(:user)

        visit new_user_session_path
        signin(admin)
        admin_changes_email_address(user: another_user, new_email: "new@email.com")
        signout

        assert_equal "new@email.com", last_email.to[0]
        assert_equal 'Confirm your email change', last_email.subject

        another_user.reload
        visit user_confirmation_path(confirmation_token: another_user.confirmation_token)

        assert_response_contains("Confirm a change to your account email")
        fill_in "Passphrase", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
        click_button "Confirm email change"

        assert_response_contains("Your account was successfully confirmed. You are now signed in.")
      end
    end
  end
end
