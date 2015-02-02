require 'test_helper'
require 'helpers/user_account_operations'

class EmailChangeTest < ActionDispatch::IntegrationTest
  include UserAccountOperations

  context "by an admin" do
    setup do
      @admin = create(:user, role: "admin")
    end

    context "for an active user" do
      should "send a notification email and not confirmation email" do
        Sidekiq::Testing.inline! do
          user = create(:user)

          visit new_user_session_path
          signin(@admin)
          admin_changes_email_address(user: user, new_email: "new@email.com")

          assert_equal "new@email.com", last_email.to[0]
          assert_equal 'Your GOV.UK Signon email address has been updated', last_email.subject
        end
      end

      should "log the event in the user's event log" do
        Sidekiq::Testing.inline! do
          user = create(:user, email: 'old@email.com')

          visit new_user_session_path
          signin(@admin)
          admin_changes_email_address(user: user, new_email: "new@email.com")

          visit event_logs_user_path(user)
          assert_response_contains "Email changed by #{@admin.name} from old@email.com to new@email.com"
        end
      end

      should "show an error and not trigger a notification if the email is blank" do
        user = create(:user)

        visit new_user_session_path
        signin(@admin)
        admin_changes_email_address(user: user, new_email: "")

        assert_response_contains("Email can't be blank")
        assert_nil last_email
      end
    end

    context "for a user who hasn't accepted their invite yet" do
      should "resend the invitation" do
        Sidekiq::Testing.inline! do
          user = User.invite!(name: "Jim", email: "jim@web.com")

          visit new_user_session_path
          signin(@admin)
          admin_changes_email_address(user: user, new_email: "new@email.com")

          invitation_email = ActionMailer::Base.deliveries[-3]
          assert_equal "new@email.com", invitation_email.to[0]
          assert_equal 'Please confirm your account', invitation_email.subject

          user.reload
          accept_invitation(invitation_token: user.invitation_token,
                            password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z")
          assert_response_contains("Your passphrase was set successfully. You are now signed in.")
        end
      end
    end

    context "when the change was made in error" do
      should "be cancellable" do
        use_javascript_driver

        user = create(:user_with_pending_email_change)
        original_email = user.email

        visit new_user_session_path
        signin(@admin)
        visit edit_user_path(user)
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

    should "trigger a confirmation email to the user's new address and a notification to the user's old address" do
      visit new_user_session_path
      signin(@user)

      click_link "Change your email or passphrase"
      fill_in "Email", with: "new@email.com"
      click_button "Change email"

      confirmation_email, notification_email = *ActionMailer::Base.deliveries[-2..-1]
      assert_equal "new@email.com", confirmation_email.to.first
      assert_equal 'Confirm your email change', confirmation_email.subject
      assert_equal "original@email.com", notification_email.to.first
      assert_equal 'Your GOV.UK Signon email address is being changed', notification_email.subject
    end

    should "log email change events in the user's event log" do
      visit new_user_session_path
      signin(@user)

      click_link "Change your email or passphrase"
      fill_in "Email", with: "new@email.com"
      click_button "Change email"

      visit user_confirmation_path(confirmation_token: @user.reload.confirmation_token)

      signout
      signin(create(:admin_user))
      visit event_logs_user_path(@user)
      assert_response_contains "Email change initiated by #{@user.name} from original@email.com to new@email.com"
      assert_response_contains "Email change confirmed"
    end

    should "show an error and not send a confirmation if the email is blank" do
      visit new_user_session_path
      signin(@user)

      click_link "Change your email or passphrase"
      fill_in "Email", with: ""
      click_button "Change email"

      assert_response_contains "Email can't be blank"

      assert_nil last_email
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
