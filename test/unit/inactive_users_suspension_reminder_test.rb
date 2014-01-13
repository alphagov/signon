require 'test_helper'

class InactiveUsersSuspensionReminderTest < ActiveSupport::TestCase

  context "users by days to suspension" do
    setup do
      @in_1  = create(:user, current_sign_in_at: SUSPENSION_THRESHOLD_PERIOD.days.ago)
      @in_3  = create(:user, current_sign_in_at: (SUSPENSION_THRESHOLD_PERIOD - 2).days.ago)
      @in_7  = create(:user, current_sign_in_at: (SUSPENSION_THRESHOLD_PERIOD - 6).days.ago)
      @in_14 = create(:user, current_sign_in_at: (SUSPENSION_THRESHOLD_PERIOD - 13).days.ago)
    end

    def users_by_days_to_suspension
      InactiveUsersSuspensionReminder.new.users_by_days_to_suspension
    end

    should "select users whose accounts will get suspended in 1 days" do
      assert_equal [@in_1], users_by_days_to_suspension[1]
    end

    should "select users whose accounts will get suspended in 3 days" do
      assert_equal [@in_3], users_by_days_to_suspension[3]
    end

    should "select users whose accounts will get suspended in 7 days" do
      assert_equal [@in_7], users_by_days_to_suspension[7]
    end

    should "select users whose accounts will get suspended in 14 days" do
      assert_equal [@in_14], users_by_days_to_suspension[14]
    end

    should "select users whose signed-in more than SUSPENSION_THRESHOLD_PERIOD days ago" do
      signed_in_48_days_ago = create(:user, current_sign_in_at: 48.days.ago)
      assert_include users_by_days_to_suspension[1], signed_in_48_days_ago
    end
  end

  context "sucessfully sending mails" do
    setup do
      @in_1  = create(:user, current_sign_in_at: SUSPENSION_THRESHOLD_PERIOD.days.ago)
      @in_3  = create(:user, current_sign_in_at: (SUSPENSION_THRESHOLD_PERIOD - 2).days.ago)
      @in_7  = create(:user, current_sign_in_at: (SUSPENSION_THRESHOLD_PERIOD - 6).days.ago)
      @in_14 = create(:user, current_sign_in_at: (SUSPENSION_THRESHOLD_PERIOD - 13).days.ago)
    end

    should "send mails to users to remind" do
      mailer = mock()
      mailer.expects(:deliver).returns(true).at_most(4)
      UserMailer.expects(:suspension_reminder).with(@in_1, 1).returns(mailer)
      UserMailer.expects(:suspension_reminder).with(@in_3, 3).returns(mailer)
      UserMailer.expects(:suspension_reminder).with(@in_7, 7).returns(mailer)
      UserMailer.expects(:suspension_reminder).with(@in_14, 14).returns(mailer)

      InactiveUsersSuspensionReminder.new.send_reminders
    end

    should "return number of reminders sent" do
      signed_in_48_days_ago = create(:user, current_sign_in_at: 48.days.ago)

      assert_equal 5, InactiveUsersSuspensionReminder.new.send_reminders
    end
  end

  context "faling to send emails" do
    should "retry 2 times if there are errors connecting to SES" do
      create(:user, current_sign_in_at: SUSPENSION_THRESHOLD_PERIOD.days.ago)

      mailer = mock()
      mailer.expects(:deliver).raises(Errno::ETIMEDOUT).at_most(3)
      UserMailer.expects(:suspension_reminder).returns(mailer).at_most(3)

      InactiveUsersSuspensionReminder.new.send_reminders
    end
  end

end
