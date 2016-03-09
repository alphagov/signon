require 'test_helper'

class NoisyBatchInvitationTest < ActionMailer::TestCase
  context "make_noise" do
    setup do
      user = create(:user, name: "Bob Loblaw")
      @batch_invitation = create(:batch_invitation, user: user)
      create(:batch_invitation_user, batch_invitation: @batch_invitation)
      @email = NoisyBatchInvitation.make_noise(@batch_invitation).deliver_now
    end

    should "come from noreply-signon@" do
      assert_match /".* Signon development" <noreply-signon-development@.*\.gov\.uk>/, @email[:from].to_s
    end

    should "send to noreply-signon@" do
      assert_equal @email.to.count, 1
      assert_match /signon-alerts@.*\.gov\.uk/, @email.to.first
    end

    should "have a subject" do
      assert_match(/SIGNON/i, @email.subject)
      assert_match(/Created a Batch/i, @email.subject)
    end

    should "mention the count and the user who initiated it" do
      assert_match(/batch of 1 users/, @email.encoded)
      assert_match(/Bob Loblaw/, @email.encoded)
    end

    should "link to the batch" do
      url = "/batch_invitations/#{@batch_invitation.id}"
      assert_match(/#{Regexp.escape(url)}/, @email.encoded)
    end
  end

  context "make_noise when instance_name has been set" do
    setup do
      Rails.application.config.stubs(:instance_name).returns("Test Fools")

      user = create(:user, name: "Bob Loblaw")
      @batch_invitation = create(:batch_invitation, user: user)
      create(:batch_invitation_user, batch_invitation: @batch_invitation)
      @email = NoisyBatchInvitation.make_noise(@batch_invitation).deliver_now
    end

    should "from address should include the instance name" do
      assert_match /".* Signon Test Fools" <noreply-signon-test-fools@.*\.gov\.uk>/, @email[:from].to_s
    end
  end

  context "work correctly when no instance name is set" do
    setup do
      Rails.application.config.stubs(:instance_name).returns(nil)

      user = create(:user, name: "Bob Loblaw")
      @batch_invitation = create(:batch_invitation, user: user)
      create(:batch_invitation_user, batch_invitation: @batch_invitation)
      @email = NoisyBatchInvitation.make_noise(@batch_invitation).deliver_now
    end

    should "from address should include the instance name" do
      assert_match /".* Signon" <noreply-signon@.*\.gov\.uk>/, @email[:from].to_s
    end
  end
end
