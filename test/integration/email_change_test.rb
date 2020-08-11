require "test_helper"
require "support/user_account_helpers"

class EmailChangeTest < ActionDispatch::IntegrationTest
  include UserAccountHelpers
  include ActiveJob::TestHelper

  context "by an admin" do
    setup do
      @admin = create(:admin_user)
    end

    context "for an active user" do
      should "send a notification email and not confirmation email" do
        perform_enqueued_jobs do
          user = create(:user)

          visit new_user_session_path
          signin_with(@admin)
          admin_changes_email_address(user: user, new_email: "new@email.com")

          assert_equal "new@email.com", last_email.to[0]
          assert_match(/Your .* Signon development email address has been updated/, last_email.subject)
        end
      end

      should "log the event in the user's event log" do
        perform_enqueued_jobs do
          user = create(:user, email: "old@email.com")

          visit new_user_session_path
          signin_with(@admin)
          admin_changes_email_address(user: user, new_email: "new@email.com")

          visit event_logs_user_path(user)
          assert_response_contains "Email changed by #{@admin.name} from old@email.com to new@email.com"
        end
      end

      should "show an error and not trigger a notification if the email is blank" do
        user = create(:user)

        visit new_user_session_path
        signin_with(@admin)
        admin_changes_email_address(user: user, new_email: "")

        assert_response_contains("Email can't be blank")
        assert_nil last_email
      end
    end

    context "for a user who hasn't accepted their invite yet" do
      should "resend the invitation" do
        perform_enqueued_jobs do
          ActionMailer::Base.deliveries.clear
          user = User.invite!(name: "Jim", email: "jim@web.com")

          open_email("jim@web.com")
          assert_equal "Please confirm your account", current_email.subject

          visit new_user_session_path
          signin_with(@admin)
          admin_changes_email_address(user: user, new_email: "new@email.com")

          email = emails_sent_to("new@email.com").detect { |mail| mail.subject == "Please confirm your account" }
          assert email
          assert email.body.include?("/users/invitation/accept?invitation_token=")
          assert user.accept_invitation!
        end
      end
    end

    context "when the change was made in error" do
      should "be cancellable" do
        use_javascript_driver

        user = create(:user_with_pending_email_change)

        confirmation_token = token_sent_to(user)
        original_email = user.email

        visit new_user_session_path
        signin_with(@admin)
        visit edit_user_path(user)
        click_link "Cancel change"
        signout

        visit user_confirmation_path(confirmation_token: confirmation_token)
        assert_response_contains("Couldn't confirm email change. Please contact support to request a new confirmation email.")
        assert_equal original_email, user.reload.email
      end
    end
  end

  context "by a user themselves" do
    setup do
      @user = create(:user, email: "original@email.com")
    end

    should "trigger a confirmation email to the user's new address and a notification to the user's old address" do
      perform_enqueued_jobs do
        visit new_user_session_path
        signin_with(@user)

        click_link "Change your email or password"
        fill_in "Email", with: "new@email.com"
        click_button "Change email"

        confirmation_email, notification_email = *ActionMailer::Base.deliveries[-2..-1]
        assert_equal "new@email.com", confirmation_email.to.first
        assert_equal "Confirm your email change", confirmation_email.subject
        assert_equal "original@email.com", notification_email.to.first
        assert_match(/Your .* Signon development email address is being changed/, notification_email.subject)
      end
    end

    should "log email change events in the user's event log" do
      perform_enqueued_jobs do
        visit new_user_session_path
        signin_with(@user)

        click_link "Change your email or password"
        fill_in "Email", with: "new@email.com"
        click_button "Change email"

        first_email_sent_to("new@email.com").find_link(href: false).click

        signout
        signin_with(create(:admin_user))
        visit event_logs_user_path(@user)
        assert_response_contains "Email change initiated by #{@user.name} from original@email.com to new@email.com"
        assert_response_contains "Email change confirmed"
      end
    end

    should "show an error and not send a confirmation if the email is blank" do
      visit new_user_session_path
      signin_with(@user)

      click_link "Change your email or password"
      fill_in "Email", with: ""
      click_button "Change email"

      assert_response_contains "Email can't be blank"

      assert_nil last_email
    end

    should "be cancellable" do
      use_javascript_driver

      visit new_user_session_path
      signin_with(@user)

      click_link "Change your email or password"
      fill_in "Email", with: "new@email.com"
      click_button "Change email"

      confirmation_token = token_sent_to(@user)

      click_link "Change your email or password"
      click_link "Cancel change"
      signout

      visit user_confirmation_path(confirmation_token: confirmation_token)
      assert_response_contains("Couldn't confirm email change. Please contact support to request a new confirmation email.")
      assert_equal "original@email.com", @user.reload.email
    end

    should "allow a signed in user to complete email change" do
      @user.update!(unconfirmed_email: "new@email.com")
      confirmation_token = token_sent_to(@user)

      visit new_user_session_path
      signin_with(@user)

      visit user_confirmation_path(confirmation_token: confirmation_token)
      assert_response_contains("Your account was successfully confirmed. You are now signed in.")
      assert_equal "new@email.com", @user.reload.email
    end

    should "disallow a signed in user completing an email change for another account" do
      @user.update!(unconfirmed_email: "new@email.com")
      confirmation_token = token_sent_to(@user)
      @other_user = create(:user, email: "dave@email.com")

      visit new_user_session_path
      signin_with(@other_user)

      visit user_confirmation_path(confirmation_token: confirmation_token)
      assert_response_contains("It appears you followed a link meant for another user.")
      assert_equal "original@email.com", @user.reload.email
    end

    should "prompt unauthenticated user for password when changing email" do
      password = "L0ng S3cure P4ssw0rd111"
      @user.update!(
        unconfirmed_email: "new@email.com",
        password: password,
      )

      confirm_email_change(
        password: password,
        confirmation_token: token_sent_to(@user),
      )
      assert_equal "new@email.com", @user.reload.email
    end
  end
end
