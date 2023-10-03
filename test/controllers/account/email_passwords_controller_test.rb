require "test_helper"

class Account::EmailPasswordsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  context "PUT update_email" do
    setup do
      @user = create(:user, email: "old@email.com")
      sign_in @user
    end

    context "changing an email" do
      should "stage the change, send a confirmation email to the new address and email change notification to the old address" do
        perform_enqueued_jobs do
          put :update_email, params: { user: { email: "new@email.com" } }

          @user.reload

          assert_equal "new@email.com", @user.unconfirmed_email
          assert_equal "old@email.com", @user.email

          confirmation_email = ActionMailer::Base.deliveries[-2]
          assert_equal "Confirm your email change", confirmation_email.subject
          assert_equal "new@email.com", confirmation_email.to.first

          email_changed_notification = ActionMailer::Base.deliveries.last
          assert_match(/Your .* Signon development email address is being changed/, email_changed_notification.subject)
          assert_equal "old@email.com", email_changed_notification.to.first
        end
      end

      should "confirm the change in a flash notice" do
        put :update_email, params: { user: { email: "new@email.com" } }

        assert_match(/An email has been sent to new@email\.com/, flash[:notice])
      end

      should "log an event" do
        put :update_email, params: { user: { email: "new@email.com" } }
        assert_equal 1, EventLog.where(event_id: EventLog::EMAIL_CHANGE_INITIATED.id, uid: @user.uid, initiator_id: @user.id).count
      end

      should "redirect to account page" do
        put :update_email, params: { user: { email: "new@email.com" } }
        assert_redirected_to account_path
      end
    end
  end

  def change_user_password(user_factory, new_password)
    original_password = "I am a very original password. Refrigerator weevil."
    user = create(user_factory, password: original_password)
    original_password_hash = user.encrypted_password
    sign_in user

    post :update_password,
         params: {
           user: {
             current_password: original_password,
             password: new_password,
             password_confirmation: new_password,
           },
         }

    [user, original_password_hash]
  end

  context "PUT update_password" do
    should "changing passwords to something strong should succeed" do
      user, orig_password = change_user_password(:user, "destabilizers842}orthophosphate")

      assert_redirected_to account_path

      user.reload
      assert_not_equal orig_password, user.encrypted_password
    end

    should "changing password to something too short should fail" do
      user, orig_password = change_user_password(:user, "short")

      assert_equal "200", response.code
      assert_match "too short", response.body

      user.reload
      assert_equal orig_password, user.encrypted_password
    end

    should "changing password to something too weak should fail" do
      user, orig_password = change_user_password(:user, "zymophosphate")

      assert_equal "200", response.code
      assert_match "not strong enough", response.body

      user.reload
      assert_equal orig_password, user.encrypted_password
    end
  end

  context "PUT resend_email_change" do
    should "send an email change confirmation email" do
      perform_enqueued_jobs do
        @user = create(:user_with_pending_email_change)
        sign_in @user

        put :resend_email_change

        assert_equal "Confirm your email change", ActionMailer::Base.deliveries.last.subject
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
          confirmation_token: "old token",
          confirmation_sent_at: 15.days.ago,
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
