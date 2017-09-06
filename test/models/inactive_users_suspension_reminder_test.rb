require 'test_helper'

class InactiveUsersSuspensionReminderTest < ActiveSupport::TestCase
  context "sending reminder emails" do
    should "send reminder emails to users when 1 day from suspension" do
      suspends_in_1_day = create(:user, current_sign_in_at: (User::SUSPENSION_THRESHOLD_PERIOD).ago)

      mailer = mock
      mailer.expects(:deliver_now).returns(true)
      UserMailer.expects(:suspension_reminder).with(suspends_in_1_day, 1).returns(mailer)

      users_to_remind = User.last_signed_in_on((User::SUSPENSION_THRESHOLD_PERIOD).ago)
      InactiveUsersSuspensionReminder.new(users_to_remind, 1).send_reminders
    end

    should "send reminder emails to users when 3 days from suspension" do
      suspends_in_3_days = create(:user, current_sign_in_at: (User::SUSPENSION_THRESHOLD_PERIOD - 2.days).ago)

      mailer = mock
      mailer.expects(:deliver_now).returns(true)
      UserMailer.expects(:suspension_reminder).with(suspends_in_3_days, 3).returns(mailer)

      users_to_remind = User.last_signed_in_on((User::SUSPENSION_THRESHOLD_PERIOD - 2.days).ago)
      InactiveUsersSuspensionReminder.new(users_to_remind, 3).send_reminders
    end

    should "send reminder emails to users when 7 days from suspension" do
      suspends_in_7_days = create(:user, current_sign_in_at: (User::SUSPENSION_THRESHOLD_PERIOD - 6.days).ago)

      mailer = mock
      mailer.expects(:deliver_now).returns(true)
      UserMailer.expects(:suspension_reminder).with(suspends_in_7_days, 7).returns(mailer)

      users_to_remind = User.last_signed_in_on((User::SUSPENSION_THRESHOLD_PERIOD - 6.days).ago)
      InactiveUsersSuspensionReminder.new(users_to_remind, 7).send_reminders
    end

    should "send reminder emails to users when 14 days from suspension" do
      suspends_in_14_days = create(:user, current_sign_in_at: (User::SUSPENSION_THRESHOLD_PERIOD - 13.days).ago)

      mailer = mock
      mailer.expects(:deliver_now).returns(true)
      UserMailer.expects(:suspension_reminder).with(suspends_in_14_days, 14).returns(mailer)

      users_to_remind = User.last_signed_in_on((User::SUSPENSION_THRESHOLD_PERIOD - 13.days).ago)
      InactiveUsersSuspensionReminder.new(users_to_remind, 14).send_reminders
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
      GovukError.expects(:notify).once
      UserMailer.expects(:suspension_reminder).returns(@mailer).times(3)

      InactiveUsersSuspensionReminder.new(@users_to_remind, 1).send_reminders
    end
  end
end
