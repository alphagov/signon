require "test_helper"

class MandatingTwoStepVerificationTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ActiveJob::TestHelper

  def sign_in_as_and_edit_user(sign_in_as, user_to_edit)
    visit root_path
    signin_with(sign_in_as)
    visit edit_user_path(user_to_edit)
  end

  def assert_admin_can_send_2fa_email(admin, user)
    sign_in_as_and_edit_user(admin, user)

    perform_enqueued_jobs do
      check "Ask user to set up 2-step verification"
      click_button "Update User"

      assert last_email
      assert_equal "Make your Signon account more secure", last_email.subject
    end

    assert user.reload.require_2sv
  end

  def assert_admin_can_remove_2sv_requirement_without_notifying_user(admin, user)
    sign_in_as_and_edit_user(admin, user)

    perform_enqueued_jobs do
      uncheck "Ask user to set up 2-step verification"
      click_button "Update User"

      assert_not last_email
    end

    assert_not user.reload.require_2sv
  end

  setup do
    @organisation = create(:organisation)
    @child_organisation = create(:organisation, parent: @organisation)
    @user = create(:user, organisation: @organisation)
    @user_in_child_organisation = create(:user, organisation: @child_organisation)
  end

  context "when logged in as a super admin" do
    setup do
      @super_admin = create(:superadmin_user)
    end

    should "be able to send a notification to a user to set up 2fa" do
      assert_admin_can_send_2fa_email(@super_admin, @user)
    end

    should "be able to unset the requirement for 2fa" do
      assert_admin_can_remove_2sv_requirement_without_notifying_user(@super_admin, @user)
    end
  end

  context "when logged in as an admin" do
    setup do
      @admin = create(:admin_user)
    end

    should "be able to send a notification to a user to set up 2fa" do
      assert_admin_can_send_2fa_email(@admin, @user)
    end

    should "be able to unset the requirement for 2fa" do
      assert_admin_can_remove_2sv_requirement_without_notifying_user(@admin, @user)
    end
  end

  context "when logged in as a super organisation admin" do
    setup do
      @super_org_admin = create(:super_org_admin, organisation: @user.organisation)
    end

    should "be able to send a notification to a user to set up 2fa" do
      assert_admin_can_send_2fa_email(@super_org_admin, @user)
    end

    should "be able to unset the requirement for 2fa" do
      assert_admin_can_remove_2sv_requirement_without_notifying_user(@super_org_admin, @user)
    end

    should "be able to send a notification to a user in a child organisation to set up 2fa" do
      assert_admin_can_send_2fa_email(@super_org_admin, @user_in_child_organisation)
    end

    should "be able to unset the requirement for 2fa for a user in a child organisation" do
      assert_admin_can_remove_2sv_requirement_without_notifying_user(@super_org_admin, @user_in_child_organisation)
    end
  end

  context "when logged in as an organisation admin" do
    setup do
      @org_admin = create(:organisation_admin, organisation: @user.organisation)
    end

    should "be able to send a notification to a user to set up 2fa" do
      assert_admin_can_send_2fa_email(@org_admin, @user)
    end

    should "be able to unset the requirement for 2fa" do
      assert_admin_can_remove_2sv_requirement_without_notifying_user(@org_admin, @user)
    end
  end

  context "when logged in as a normal user" do
    should "not be able to view any 2fa actions" do
      non_admin_user = create(:user, organisation: @user.organisation)
      sign_in_as_and_edit_user(non_admin_user, @user)

      assert page.has_no_text? "Ask user to set up 2-step verification"
    end
  end
end
