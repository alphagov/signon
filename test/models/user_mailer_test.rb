require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  def assert_body_includes(search_string, email=@email)
    email.body.parts.each do |part|
      assert_include part.body, search_string
    end
  end

  context "emailing a user" do
    setup do
      stub_user = stub(name: "User", email: "user@example.com")
      @email = UserMailer.suspension_reminder(stub_user, 3)
    end

    should "include the number of days remaining in the subject" do
      assert_include @email.subject, "in 3 days"
    end

    should "include the number of days remaining in the body" do
      assert_body_includes "in 3 days"
    end

    should "not include an instance name in the subject" do
      assert_include @email.subject, "Your GOV.UK Signon account"
    end

    should "not include an instance name in the body" do
      assert_body_includes "Signon account, for"
    end
  end

  context "emailing a user to be suspended tomorrow" do
    setup do
      stub_user = stub(name: "User", email: "user@example.com")
      @email = UserMailer.suspension_reminder(stub_user, 1)
    end

    should "say 'tomorrow' in the subject" do
      assert_include @email.subject, "tomorrow"
    end

    should "say 'tomorrow' in the body" do
      assert_body_includes "tomorrow"
    end
  end

  context "on a named Signon instance" do
    setup do
      Rails.application.config.stubs(:instance_name).returns("test")
      stub_user = stub(name: "User", email: "user@example.com")
      @email = UserMailer.suspension_reminder(stub_user, 3)
    end

    should "include the instance name in the subject" do
      assert_include @email.subject, "Your GOV.UK Signon test account"
    end

    should "include the instance name in the body" do
      assert_body_includes "Signon test account, for"
    end
  end

  context "emailing a user to explain why their account is locked" do
    setup do
      Rails.application.config.stubs(:instance_name).returns("test")
      @the_time = Time.zone.now
      stub_user = stub(name: "User", email: "user@example.com", locked_at: @the_time)
      @email = UserMailer.locked_account_explanation(stub_user)
    end

    should "state when the account was locked" do
      assert_body_includes "was locked at #{@the_time.to_s(:govuk_date)}"
    end

    should "state when the account will be unlocked" do
      assert_body_includes "Your account will be unlocked at #{(@the_time + 1.hour).to_s(:govuk_date)}"
    end
  end

  context "emailing a user to notify that reset password is dis-allowed" do
    should "mention that reset is disallowed because their account is suspended" do
      stub_user = stub(name: 'User', email: 'user@example.com')
      email = UserMailer.notify_reset_password_disallowed_due_to_suspension(stub_user)

      assert_body_includes "You can't request a passphrase reset on a suspended account.", email
    end
  end
end
