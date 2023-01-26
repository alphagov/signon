require "test_helper"

class ResetTwoStepVerificationTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ActiveJob::TestHelper

  setup do
    @organisation = create :organisation
    @child_organisation = create(:organisation, parent: @organisation)
    @user = create(:two_step_enabled_user, organisation: @organisation)
    @user_in_child_organisation = create(:two_step_enabled_user, organisation: @child_organisation)
    @user_in_different_organisation = create(:two_step_enabled_user, organisation: create(:organisation))
  end

  def assert_2sv_can_be_reset(logged_in_as, user_to_be_reset)
    use_javascript_driver

    visit edit_user_path(user_to_be_reset)
    signin_with(logged_in_as)

    perform_enqueued_jobs do
      assert_response_contains "2-step verification enabled"

      accept_alert do
        click_link "Reset 2-step verification"
      end

      assert_response_contains "Reset 2-step verification for #{user_to_be_reset.email}"

      assert last_email
      assert_equal "2-step verification has been reset", last_email.subject
    end
  end

  def assert_2sv_cannot_be_reset(logged_in_as, user_to_be_reset)
    use_javascript_driver

    visit edit_user_path(user_to_be_reset)
    signin_with(logged_in_as)

    assert page.has_no_link? "Reset 2-step verification"
  end

  context "when logged in as a super admin" do
    setup do
      @super_admin = create(:superadmin_user)
    end

    should "reset 2-step verification and notify the chosen user by email for users in any organisation" do
      assert_2sv_can_be_reset(@super_admin, @user)
    end
  end

  context "when logged in as a regular admin" do
    setup do
      @admin = create(:admin_user, organisation: @organisation)
    end

    should "reset 2-step verification and notify the chosen user by email for users in any organisation" do
      assert_2sv_can_be_reset(@admin, @user)
    end
  end

  context "when logged in as an organisation super admin" do
    setup do
      @super_org_admin = create(:super_org_admin, organisation: @organisation)
    end

    should "be able to reset 2-step verification and notify the chosen user by email if they belong to the same org as the user" do
      assert_2sv_can_be_reset(@super_org_admin, @user)
    end

    should "be able to reset 2-step verification and notify the chosen user by email if the user is in a child organisation" do
      assert_2sv_can_be_reset(@super_org_admin, @user_in_child_organisation)
    end

    should "not be able to reset 2-step verification and notify the chosen user by email if the user is in a different organisation" do
      assert_2sv_cannot_be_reset(@super_org_admin, @user_in_different_organisation)
    end
  end

  context "when logged in as an organisation admin" do
    setup do
      @organisation_admin = create(:organisation_admin, organisation: @organisation)
    end

    should "be able to reset 2-step verification and notify the chosen user by email if they belong to the same org as the user" do
      assert_2sv_can_be_reset(@organisation_admin, @user)
    end

    should "not be able to reset 2-step verification and notify the chosen user by email if the user is in a child organisation" do
      assert_2sv_cannot_be_reset(@organisation_admin, @user_in_child_organisation)
    end

    should "not be able to reset 2-step verification and notify the chosen user by email if the user is in a different organisation" do
      assert_2sv_cannot_be_reset(@organisation_admin, @user_in_different_organisation)
    end
  end

  context "when logged in as a normal user" do
    setup do
      @normal_user = create(:user, organisation: @organisation)
    end

    should "not be able to reset 2sv" do
      assert_2sv_cannot_be_reset(@normal_user, @user)
    end
  end
end
