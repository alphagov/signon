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

      should "log an event" do
        put :update_email, params: { user: { email: "new@email.com" } }
        assert_equal 1, EventLog.where(event_id: EventLog::EMAIL_CHANGE_INITIATED.id, uid: @user.uid, initiator_id: @user.id).count
      end
    end
  end
end
