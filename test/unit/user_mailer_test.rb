require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  context "emailing a user" do
    setup do
      stub_user = stub(name: "User", email: "user@example.com")
      @email = UserMailer.suspension_reminder(stub_user, 3)
    end

    should "include the number of days remaining in the subject" do
      assert_include @email.subject, "in 3 days"
    end

    should "not include an instance name in the subject" do
      assert_include @email.subject, "Your GOV.UK Signon account"
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
  end
end
