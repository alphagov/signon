require "test_helper"

class ManagingTwoStepVerificationTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ManagingTwoSvHelpers

  setup do
    @organisation = create(:organisation)
    @child_organisation = create(:organisation, parent: @organisation)
  end

  context "Mandating 2-step verification" do
    setup do
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

      should "remove the user's exemption reason when 2SV is mandated" do
        user = create(:two_step_exempted_user)

        sign_in_as_and_edit_user(@super_admin, user)
        mandate_2sv_for_exempted_user

        assert_nil user.reload.reason_for_2sv_exemption

        expected_account_logs = [
          "Exemption from 2-step verification removed by #{@super_admin.name}",
          "2-step verification setup mandated at next login by #{@super_admin.name}"
        ]
        assert_user_access_log_contains_messages(user, expected_account_logs)
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

        assert page.has_no_text? "Mandate 2-step verification for this user"
      end
    end

    context "when a user has already had 2sv mandated" do
      setup do
        @org_admin = create(:organisation_admin, organisation: @organisation)
      end

      should "be able to see an appropriate message reflecting the user's 2sv status when enabled but not set up" do
        user = create(:two_step_enabled_user, organisation: @organisation)
        sign_in_as_and_edit_user(@org_admin, user)

        assert page.has_text? "2-step verification enabled"
        assert page.has_no_text? "Mandate 2-step verification for this user"
      end

      should "be able to see an appropriate message reflecting the user's 2sv status when 2sv set up" do
        user = create(:two_step_mandated_user, organisation: @organisation)
        sign_in_as_and_edit_user(@org_admin, user)

        assert page.has_text? "2-step verification required but not set up"
        assert page.has_no_text? "Mandate 2-step verification for this user"
      end
    end
  end
end
