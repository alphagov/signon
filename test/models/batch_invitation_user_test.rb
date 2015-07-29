require 'test_helper'

class BatchInvitationUserTest < ActiveSupport::TestCase
  context "invite" do
    setup do
      @inviting_user = create(:admin_user)
      @batch_invitation = create(:batch_invitation, :with_organisation, user: @inviting_user)
    end

    should "store invitation attributes against a user" do
      user = create(:batch_invitation_user, batch_invitation: @batch_invitation)

      # the attributes that're passed to User#invite! should be a permitted
      # params object
      invitation_attributes = ActionController::Parameters.new({
        name: user.name,
        email: user.email,
        organisation_id: @batch_invitation.organisation_id,
        supported_permission_ids: [1, 2, 3]
      })
      User.expects(:invite!).with(invitation_attributes, @inviting_user)

      user.invite(@inviting_user, [1, 2, 3])
    end

    context "success" do
      should "record the outcome against the user" do
        user = create(:batch_invitation_user, batch_invitation: @batch_invitation)
        user.invite(@inviting_user, [])

        assert_equal "success", user.reload.outcome
      end
    end

    context "user already exists" do
      should "record the outcome against the user" do
        create(:user, name: "A", email: "a@m.com")
        user = create(:batch_invitation_user, batch_invitation: @batch_invitation, email: 'a@m.com')
        user.invite(@inviting_user, [])

        assert_equal "skipped", user.reload.outcome
      end
    end

    context "the user could not be saved (eg email is blank)" do
      should "record it as a failure" do
        user = create(:batch_invitation_user, batch_invitation: @batch_invitation, email: nil)
        user.invite(@inviting_user, [])

        assert_equal "failed", user.reload.outcome
      end
    end
  end
end
