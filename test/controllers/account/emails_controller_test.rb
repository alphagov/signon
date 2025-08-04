require "test_helper"

class Account::EmailsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  context "GET edit" do
    setup do
      @user = create(:user, email: "old@email.com")
      sign_in @user
    end

    should "display form with current email address" do
      get :edit

      assert_select "form[action='#{account_email_path}']" do
        assert_select "input[name='user[email]']", value: @user.email
      end
    end
  end

  context "PUT update" do
    setup do
      @user = create(:user, email: "old@email.com")
      sign_in @user
    end

    context "changing an email" do
      should "stage the change, send a confirmation email to the new address and email change notification to the old address" do
        perform_enqueued_jobs do
          put :update, params: { user: { email: "new@email.com" } }

          @user.reload

          assert_equal "new@email.com", @user.unconfirmed_email
          assert_equal "old@email.com", @user.email

          confirmation_email = ActionMailer::Base.deliveries[-2]
          assert_equal "Confirm changes to your GOV.UK Signon test account", confirmation_email.subject
          assert_equal "new@email.com", confirmation_email.to.first

          email_changed_notification = ActionMailer::Base.deliveries.last
          assert_match(/Your .* Signon test email address is being changed/, email_changed_notification.subject)
          assert_equal "old@email.com", email_changed_notification.to.first
        end
      end

      should "confirm the change in a flash notice" do
        put :update, params: { user: { email: "new@email.com" } }

        assert_match(/An email has been sent to new@email\.com/, flash[:notice])
      end

      should "log an event" do
        put :update, params: { user: { email: "new@email.com" } }
        assert_equal 1, EventLog.where(event_id: EventLog::EMAIL_CHANGE_INITIATED.id, uid: @user.uid, initiator_id: @user.id).count
      end

      should "redirect to account page" do
        put :update, params: { user: { email: "new@email.com" } }
        assert_redirected_to account_path
      end
    end

    should "display error when validation fails" do
      put :update, params: { user: { email: "" } }

      assert_template :edit
      assert_select ".govuk-error-summary" do
        assert_select "a", href: "#user_email", text: "Email can't be blank"
      end
      assert_select ".govuk-form-group" do
        assert_select ".govuk-error-message", text: "Error: Email can't be blank"
        assert_select "input[name='user[email]'].govuk-input--error"
      end
    end
  end

  context "PUT resend_email_change" do
    should "send an email change confirmation email" do
      perform_enqueued_jobs do
        @user = create(:user_with_pending_email_change)
        sign_in @user

        put :resend_email_change

        assert_equal "Confirm changes to your GOV.UK Signon test account", ActionMailer::Base.deliveries.last.subject
      end
    end

    should "confirm resend in a flash notice" do
      user = create(:user_with_pending_email_change, unconfirmed_email: "new@email.com")
      sign_in user

      put :resend_email_change

      assert_match(/An email has been sent to new@email\.com/, flash[:notice])
    end

    should "use a new token if it's expired" do
      perform_enqueued_jobs do
        @user = create(
          :user_with_pending_email_change,
          :with_expired_confirmation_token,
          confirmation_token: "old token",
        )
        sign_in @user

        put :resend_email_change

        assert_not_equal "old token", @user.reload.confirmation_token
      end
    end

    should "redirect to account page" do
      @user = create(:user_with_pending_email_change)
      sign_in @user

      put :resend_email_change
      assert_redirected_to account_path
    end
  end

  context "DELETE cancel_email_change" do
    setup do
      @user = create(:user_with_pending_email_change)
      sign_in @user
    end

    should "clear the unconfirmed_email and the confirmation_token" do
      delete :cancel_email_change

      @user.reload
      assert_nil @user.unconfirmed_email
      assert_nil @user.confirmation_token
    end

    should "redirect to account page" do
      delete :cancel_email_change
      assert_redirected_to account_path
    end
  end
end
