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
      assert_body_includes "Your account will be suspended"
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
      assert_body_includes "Your test account will be suspended"
    end
  end
end
