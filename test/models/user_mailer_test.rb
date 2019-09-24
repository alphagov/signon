require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def assert_body_includes(search_string, email = @email)
    email.body.parts.each do |part|
      assert_includes part.body, search_string
    end
  end

  def assert_not_body_includes(search, email = @email)
    email.body.parts.each do |part|
      assert_not_includes part.body, search
    end
  end

  context "2-step verification set up" do
    setup do
      user = stub(name: "Ben", email: "test@example.com")
      @email = UserMailer.two_step_enabled(user)
    end

    context "in a non-production environment" do
      setup do
        Rails.application.config.stubs(instance_name: "foobar")
      end

      should "include the environment in the subject" do
        assert_includes @email.subject, "[Foobar]"
      end

      should "include the 'verify for production separately' warning" do
        assert_body_includes "separately for your Production"
      end
    end

    context "in the production environment" do
      setup do
        Rails.application.config.stubs(instance_name: nil)
      end

      should "not include the environment in the subject" do
        refute_match /^\[/, @email.subject
      end

      should "not include the 'verify for production separately' warning" do
        assert_not_body_includes "separately for your Production"
      end
    end
  end

  context "emailing a user" do
    setup do
      stub_user = stub(name: "User", email: "user@example.com")
      @email = UserMailer.suspension_reminder(stub_user, 3)
    end

    should "include the number of days remaining in the subject" do
      assert_includes @email.subject, "in 3 days"
    end

    should "include the number of days remaining in the body" do
      assert_body_includes "in 3 days"
    end

    should "include an instance name in the subject" do
      assert_match /Your .* Signon development account/, @email.subject
    end

    should "include an instance name in the body" do
      assert_body_includes "Signon development account, for"
    end
  end

  context "emailing a user to be suspended tomorrow" do
    setup do
      stub_user = stub(name: "User", email: "user@example.com")
      @email = UserMailer.suspension_reminder(stub_user, 1)
    end

    should "say 'tomorrow' in the subject" do
      assert_includes @email.subject, "tomorrow"
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
      assert_match /Your .* Signon test account/, @email.subject
    end

    should "include the instance name in the body" do
      assert_body_includes "Signon test account, for"
    end
  end

  context "emailing a user to explain why their account is locked" do
    setup do
      Rails.application.config.stubs(:instance_name).returns("test")
      @the_time = Time.zone.now
      user = User.new(name: "User", email: "user@example.com", locked_at: @the_time)
      @email = UserMailer.unlock_instructions(user, "afaketoken")
    end

    should "address the user correctly" do
      assert_body_includes "Hello User"
      assert_body_includes "for user@example.com"
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
      stub_user = stub(name: "User", email: "user@example.com")
      email = UserMailer.notify_reset_password_disallowed_due_to_suspension(stub_user)

      assert_body_includes "You can't request a password reset on a suspended account.", email
    end
  end
end
