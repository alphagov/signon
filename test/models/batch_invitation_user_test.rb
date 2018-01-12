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
        organisation_id: user.organisation_id,
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

    context "organisation slug is invalid" do
      should "record it as a failure" do
        user = create(:batch_invitation_user, batch_invitation: @batch_invitation, email: 'foo@example.com', organisation_slug: 'not-a-real-slug')
        user.invite(@inviting_user, [])

        assert_equal "failed", user.reload.outcome
      end
    end
  end

  context "#organisation_id" do
    setup do
      @batch_invitation = create(:batch_invitation, :with_organisation)
    end

    should "use the organisation_id from the batch invitation if no slug is present" do
      user = create(:batch_invitation_user, batch_invitation: @batch_invitation, organisation_slug: nil)

      assert_equal @batch_invitation.organisation_id, user.organisation_id
    end

    should "use the organisation_id from the batch invitation if a blank slug is present" do
      user = create(:batch_invitation_user, batch_invitation: @batch_invitation, organisation_slug: '')

      assert_equal @batch_invitation.organisation_id, user.organisation_id
    end

    should "raise BatchInvitationUser::InvalidOrganisationSlug if the slug is present but doesn't refer to a real org" do
      user = create(:batch_invitation_user, batch_invitation: @batch_invitation, organisation_slug: 'doesnt-exist-does-it?-eh?')

      assert_raises(BatchInvitationUser::InvalidOrganisationSlug) {
        user.organisation_id
      }
    end

    should "use the id of the organisation refered to by the slug if present" do
      local_organisation = create(:organisation, slug: 'local-slugs-for-local-organisations')

      user = create(:batch_invitation_user, batch_invitation: @batch_invitation, organisation_slug: local_organisation.slug)

      assert_equal local_organisation.id, user.organisation_id
    end
  end
end
