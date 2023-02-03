require "test_helper"

class ManagingTwoStepVerificationTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ManagingTwoSvHelpers

  setup do
    @organisation = create(:organisation)
    @child_organisation = create(:organisation, parent: @organisation)
  end

  context "Mandating and resetting 2-step verification" do
    setup do
      @user = create(:user, organisation: @organisation)
      @user_requring_2sv = create(:two_step_enabled_user, organisation: @organisation)
      @user_in_child_organisation = create(:user, organisation: @child_organisation)
      @user_requring_2sv_in_child_organisation = create(:two_step_enabled_user, organisation: @child_organisation)
      @user_in_different_organisation = create(:two_step_enabled_user, organisation: create(:organisation))
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
          "2-step verification setup mandated at next login by #{@super_admin.name}",
        ]
        assert_user_access_log_contains_messages(user, expected_account_logs)
      end

      should "reset 2-step verification and notify the chosen user by email for users in any organisation" do
        assert_2sv_can_be_reset(@super_admin, @user_requring_2sv)
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

      should "reset 2-step verification and notify the chosen user by email for users in any organisation" do
        assert_2sv_can_be_reset(@admin, @user_requring_2sv)
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

      should "be able to reset 2-step verification and notify the chosen user by email if they belong to the same org as the user" do
        assert_2sv_can_be_reset(@super_org_admin, @user_requring_2sv)
      end

      should "be able to reset 2-step verification and notify the chosen user by email if the user is in a child organisation" do
        assert_2sv_can_be_reset(@super_org_admin, @user_requring_2sv_in_child_organisation)
      end

      should "not be able to reset 2-step verification and notify the chosen user by email if the user is in a different organisation" do
        assert_2sv_cannot_be_reset(@super_org_admin, @user_in_different_organisation)
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

      should "be able to reset 2-step verification and notify the chosen user by email if they belong to the same org as the user" do
        assert_2sv_can_be_reset(@org_admin, @user_requring_2sv)
      end

      should "not be able to reset 2-step verification and notify the chosen user by email if the user is in a child organisation" do
        assert_2sv_cannot_be_reset(@org_admin, @user_requring_2sv_in_child_organisation)
      end

      should "not be able to reset 2-step verification and notify the chosen user by email if the user is in a different organisation" do
        assert_2sv_cannot_be_reset(@org_admin, @user_in_different_organisation)
      end
    end

    context "when logged in as a normal user" do
      should "not be able to view any 2fa actions" do
        non_admin_user = create(:user, organisation: @user.organisation)
        sign_in_as_and_edit_user(non_admin_user, @user)

        assert page.has_no_text? "Mandate 2-step verification for this user"
        assert page.has_no_link? "Reset 2-step verification"
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

  context "Exempting a user from 2sv" do
    context "when logged in as a gds super admin" do
      setup do
        @gds = create(:organisation, content_id: Organisation::GDS_ORG_CONTENT_ID)
        @super_admin = create(:superadmin_user, organisation: @gds)
        @reason_for_exemption = "accessibility reasons"
      end

      def exemption_message(initiator_name, reason)
        "Exempted from 2-step verification by #{initiator_name} for reason: #{reason}"
      end

      context "when the user being edited is not an admin or superadmin" do
        should "be able to see a link to exempt a user requiring 2sv from 2sv" do
          user_requiring_2sv = create(:two_step_mandated_user, organisation: @organisation)

          assert_user_can_be_exempted_from_2sv(@super_admin, user_requiring_2sv, @reason_for_exemption)
          assert_user_access_log_contains_messages(user_requiring_2sv, ["Exempted from 2-step verification by #{@super_admin.name} for reason: #{@reason_for_exemption}"])
        end

        should "be able to see a link to exempt a user who does not yet require 2sv but is not exempt" do
          user_not_requiring_2sv = create(:user, organisation: @organisation)

          assert_user_can_be_exempted_from_2sv(@super_admin, user_not_requiring_2sv, @reason_for_exemption)
          assert_user_access_log_contains_messages(user_not_requiring_2sv, ["Exempted from 2-step verification by #{@super_admin.name} for reason: #{@reason_for_exemption}"])
        end

        should "not be able to see a link to exempt a user who already has an exemption reason" do
          exempted_user = create(:two_step_exempted_user, organisation: @organisation)

          sign_in_as_and_edit_user(@super_admin, exempted_user)
          assert page.has_no_link? "Exempt user from 2-step verification"
        end

        context "when a exemption reason already exists" do
          should "be able to see a link to edit exemption reason" do
            user_requiring_2sv = create(:user, organisation: @organisation, reason_for_2sv_exemption: "user is exempt")

            sign_in_as_and_edit_user(@super_admin, user_requiring_2sv)
            click_link("Edit reason for 2-step verification exemption")

            fill_in "Reason for 2sv exemption", with: @reason_for_exemption
            click_button "Save"

            assert_user_has_been_exempted_from_2sv(user_requiring_2sv, @reason_for_exemption)

            assert_user_access_log_contains_messages(user_requiring_2sv, ["Reason for 2-step verification exemption updated by #{@super_admin.name} to: #{@reason_for_exemption}"])
          end
        end
      end

      context "when the user being edited is an admin" do
        should "not be able to see a link to exempt the user" do
          exempted_user = create(:superadmin_user, organisation: @organisation)

          sign_in_as_and_edit_user(@super_admin, exempted_user)
          assert page.has_no_link? "Exempt user from 2-step verification"
        end
      end

      context "when the user being edited is an api user" do
        setup do
          @api_user = create(:api_user)
        end

        should "not be able to see a link to exempt the user when accessing via the edit user path" do
          sign_in_as_and_edit_user(@super_admin, @api_user)
          assert page.has_no_link? "Exempt user from 2-step verification"
        end

        should "not be able to see a link to exempt the user when accessing via the edit api user path" do
          sign_in_as_and_edit_user(@super_admin, @api_user)
          visit edit_api_user_path(@api_user)

          assert page.has_no_link? "Exempt user from 2-step verification"
        end

        should "not be able to exempt an api user when accessing the edit exemption reason path directly" do
          sign_in_as_and_edit_user(@super_admin, @api_user)
          visit edit_two_step_verification_exemption_path(@api_user)

          assert page.has_text?("You do not have permission to perform this action.")
          assert_equal "/", current_path
        end
      end
    end

    context "when logged in as a non-gds super admin" do
      setup do
        @super_admin = create(:superadmin_user)
      end

      should "not be able to exempt a user requiring 2sv from 2sv" do
        user_requiring_2sv = create(:two_step_mandated_user, organisation: @organisation)

        sign_in_as_and_edit_user(@super_admin, user_requiring_2sv)

        assert page.has_no_link? "Exempt user from 2-step verification"
      end

      context "when a exemption reason already exists" do
        should "can see exemption reason but is not able to edit it" do
          reason = "user is exempt"
          user_requiring_2sv = create(:user, organisation: @organisation, reason_for_2sv_exemption: reason)

          sign_in_as_and_edit_user(@super_admin, user_requiring_2sv)

          assert page.has_text? "The user has been made exempt from 2-step verification for the following reason: #{@reason}"
          assert page.has_no_link? "Edit reason for 2-step verification exemption"
        end
      end
    end
  end
end
