require "test_helper"

class BatchInvitationsHelperTest < ActionView::TestCase
  context "#batch_invite_status_message" do
    should "state number of users processed so far when still in progress" do
      batch_invitation = create(:batch_invitation, :in_progress)
      create(:batch_invitation_user, outcome: "failed", batch_invitation:)
      create(:batch_invitation_user, outcome: "skipped", batch_invitation:)
      create(:batch_invitation_user, outcome: "success", batch_invitation:)
      create(:batch_invitation_user, outcome: nil, batch_invitation:)

      assert_equal "In progress. 3 of 4 users processed.",
                   batch_invite_status_message(batch_invitation)
    end

    should "state number of users processed when all were successful" do
      batch_invitation = create(
        :batch_invitation,
        :has_permissions,
        outcome: "success",
      )
      create(:batch_invitation_user, outcome: "skipped", batch_invitation:)
      create(:batch_invitation_user, outcome: "success", batch_invitation:)

      assert_equal "2 users processed.",
                   batch_invite_status_message(batch_invitation)
    end

    should "state number of failures if any users have failed to process" do
      batch_invitation = create(
        :batch_invitation,
        :has_permissions,
        outcome: "success",
      )
      create(:batch_invitation_user, outcome: "failed", batch_invitation:)
      create(:batch_invitation_user, outcome: "skipped", batch_invitation:)
      create(:batch_invitation_user, outcome: "success", batch_invitation:)

      assert_equal "1 error out of 3 users processed.",
                   batch_invite_status_message(batch_invitation)
    end

    should "explain the problem for a batch invitation that has no permissions" do
      batch_invitation = create(:batch_invitation)

      assert_equal "Batch invitation doesn't have any permissions yet.",
                   batch_invite_status_message(batch_invitation)
    end
  end

  context "#batch_invite_organisation_for_user" do
    context "when the batch invitation user raises an invalid slug error when asked for organisation_id" do
      setup do
        @user = FactoryBot.create(:batch_invitation_user, organisation_slug: "department-of-hats")
      end

      should "return the empty string" do
        assert_equal "", batch_invite_organisation_for_user(@user)
      end
    end

    context "when the batch invitation user raises an active record not found error when asked for organisation_id" do
      setup do
        @invite = FactoryBot.create(:batch_invitation, organisation_id: -1)
        @user = FactoryBot.create(:batch_invitation_user, organisation_slug: nil, batch_invitation: @invite)
      end

      should "return the empty string" do
        assert_equal "", batch_invite_organisation_for_user(@user)
      end
    end

    context "when the batch invitation user has a valid organisation_slug" do
      setup do
        @org = FactoryBot.create(:organisation, name: "Department of Hats", slug: "department-of-hats")
        @user = FactoryBot.create(:batch_invitation_user, organisation_slug: @org.slug)
      end

      should "return the name of the organisation" do
        assert_equal "Department of Hats", batch_invite_organisation_for_user(@user)
      end
    end

    context "when the batch invitation user has a valid organisation from the batch invite" do
      setup do
        @org = FactoryBot.create(:organisation, name: "Department of Hats", slug: "department-of-hats")
        @invite = FactoryBot.create(:batch_invitation, organisation: @org)
        @user = FactoryBot.create(:batch_invitation_user, organisation_slug: nil, batch_invitation: @invite)
      end

      should "return the name of the organisation" do
        assert_equal "Department of Hats", batch_invite_organisation_for_user(@user)
      end
    end
  end

  context "#batch_invite_status_link" do
    should "link to show the batch when it has permissions" do
      batch_invitation = create(:batch_invitation, :has_permissions, outcome: "success")

      assert_includes batch_invite_status_link(batch_invitation) {}, batch_invitation_path(batch_invitation)
    end

    should "link to show edit the permissions when it has no permissions" do
      batch_invitation = create(:batch_invitation)

      assert_includes batch_invite_status_link(batch_invitation) {}, new_batch_invitation_permissions_path(batch_invitation)
    end
  end
end
