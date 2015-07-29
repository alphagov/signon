require 'test_helper'

class InactiveUsersSuspensionReminderTest < ActiveSupport::TestCase
  context "sending reminder emails" do
    should "send reminder emails to users with the correct number of days from suspension" do
      suspends_in_3_days = create(:user, current_sign_in_at: (User::SUSPENSION_THRESHOLD_PERIOD - 2.days).ago)

      mailer = mock
      mailer.expects(:deliver_now).returns(true)
      UserMailer.expects(:suspension_reminder).with(suspends_in_3_days, 3).returns(mailer)

      users_to_remind = User.last_signed_in_on((User::SUSPENSION_THRESHOLD_PERIOD - 2.days).ago)
      InactiveUsersSuspensionReminder.new(users_to_remind, 3).send_reminders
    end
  end

  context "failing to send emails with SES down" do
    setup do
      create(:user, current_sign_in_at: User::SUSPENSION_THRESHOLD_PERIOD.ago)
      @users_to_remind = User.last_signed_in_on(User::SUSPENSION_THRESHOLD_PERIOD.ago)

      @mailer = mock
      @mailer.expects(:deliver_now).raises(Errno::ETIMEDOUT).times(3)
    end

    should "retry twice if there are errors connecting to SES" do
      UserMailer.expects(:suspension_reminder).returns(@mailer).times(3)
      InactiveUsersSuspensionReminder.new(@users_to_remind, 1).send_reminders
    end

    should "send an exception notification if retries fail" do
      Airbrake.expects(:notify_or_ignore).once
      UserMailer.expects(:suspension_reminder).returns(@mailer).times(3)

      InactiveUsersSuspensionReminder.new(@users_to_remind, 1).send_reminders
    end
  end
end
