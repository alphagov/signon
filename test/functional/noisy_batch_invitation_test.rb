require 'test_helper'

class NoisyBatchInvitationTest < ActionMailer::TestCase
  context "make_noise" do
    setup do
      user = FactoryGirl.create(:user, name: "Bob Loblaw")
      @batch_invitation = FactoryGirl.create(:batch_invitation, user: user)
      FactoryGirl.create(:batch_invitation_user, batch_invitation: @batch_invitation)
      @email = NoisyBatchInvitation.make_noise(@batch_invitation).deliver
    end

    should "come from noreply-signon@" do
      assert_equal ["noreply-signon@theodi.org"], @email.from
    end

    should "send to noreply-signon@" do
      assert_equal ["signon-alerts@theodi.org"], @email.to
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
      url = "/admin/batch_invitations/#{@batch_invitation.id}"
      assert_match(/#{Regexp.escape(url)}/, @email.encoded)
    end
  end
end
