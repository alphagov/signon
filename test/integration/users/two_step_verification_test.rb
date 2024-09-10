require "test_helper"

class Users::TwoStepVerificationTest < ActionDispatch::IntegrationTest
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

      should "be able to send a notification to a user to set up 2SV" do
        admin_can_send_2sv_email(@super_admin, @user)
      end

      should "remove the user's exemption reason when 2SV is mandated" do
        user = create(:two_step_exempted_user)

        sign_in_as_and_edit_user(@super_admin, user)
        mandate_2sv_for_exempted_user

        user.reload

        assert_nil user.reason_for_2sv_exemption
        assert_nil user.expiry_date_for_2sv_exemption

        expected_account_logs = [
          "Exemption from 2-step verification removed by #{@super_admin.name}",
          "2-step verification setup mandated at next login by #{@super_admin.name}",
        ]
        assert_user_access_log_contains_messages(user, expected_account_logs)
      end

      should "reset 2-step verification and notify the chosen user by email for users in any organisation" do
        admin_can_reset_2sv_on_user(@super_admin, @user_requring_2sv)
      end
    end

    context "when logged in as an admin" do
      setup do
        @admin = create(:admin_user)
      end

      should "be able to send a notification to a user to set up 2SV" do
        admin_can_send_2sv_email(@admin, @user)
      end

      should "reset 2-step verification and notify the chosen user by email for users in any organisation" do
        admin_can_reset_2sv_on_user(@admin, @user_requring_2sv)
      end
    end

    context "when logged in as a super organisation admin" do
      setup do
        @super_org_admin = create(:super_organisation_admin_user, organisation: @user.organisation)
      end

      should "be able to send a notification to a user to set up 2SV" do
        admin_can_send_2sv_email(@super_org_admin, @user)
      end

      should "be able to send a notification to a user in a child organisation to set up 2SV" do
        admin_can_send_2sv_email(@super_org_admin, @user_in_child_organisation)
      end

      should "be able to reset 2-step verification and notify the chosen user by email if they belong to the same org as the user" do
        admin_can_reset_2sv_on_user(@super_org_admin, @user_requring_2sv)
      end

      should "be able to reset 2-step verification and notify the chosen user by email if the user is in a child organisation" do
        admin_can_reset_2sv_on_user(@super_org_admin, @user_requring_2sv_in_child_organisation)
      end

      should "not be able to reset 2-step verification and notify the chosen user by email if the user is in a different organisation" do
        user_cannot_reset_2sv(@super_org_admin, @user_in_different_organisation)
      end
    end

    context "when logged in as an organisation admin" do
      setup do
        @org_admin = create(:organisation_admin_user, organisation: @user.organisation)
      end

      should "be able to send a notification to a user to set up 2SV" do
        admin_can_send_2sv_email(@org_admin, @user)
      end

      should "be able to reset 2-step verification and notify the chosen user by email if they belong to the same org as the user" do
        admin_can_reset_2sv_on_user(@org_admin, @user_requring_2sv)
      end

      should "not be able to reset 2-step verification and notify the chosen user by email if the user is in a child organisation" do
        user_cannot_reset_2sv(@org_admin, @user_requring_2sv_in_child_organisation)
      end

      should "not be able to reset 2-step verification and notify the chosen user by email if the user is in a different organisation" do
        user_cannot_reset_2sv(@org_admin, @user_in_different_organisation)
      end
    end

    context "when logged in as a normal user" do
      should "not be able to view any 2SV actions" do
        non_admin_user = create(:user, organisation: @user.organisation)
        sign_in_as_and_edit_user(non_admin_user, @user)

        assert page.has_no_text? "Turn on 2-step verification for this user"
        assert page.has_no_link? "Reset 2-step verification"
      end
    end

    context "when a user has already had 2sv mandated" do
      setup do
        @org_admin = create(:organisation_admin_user, organisation: @organisation)
      end

      should "be able to see an appropriate message reflecting the user's 2sv status when enabled but not set up" do
        user = create(:two_step_enabled_user, organisation: @organisation)
        sign_in_as_and_edit_user(@org_admin, user)

        assert page.has_text?(/2-step verification\s+Enabled/)
        assert page.has_no_text? "Change 2-step verification requirement for this user"
      end

      should "be able to see an appropriate message reflecting the user's 2sv status when 2sv set up" do
        user = create(:two_step_mandated_user, organisation: @organisation)
        sign_in_as_and_edit_user(@org_admin, user)

        assert page.has_text?(/2-step verification\s+Required but not set up/)
        assert page.has_no_text? "Turn on 2-step verification for this user"
      end
    end
  end

  context "Exempting a user from 2sv" do
    context "when logged in as a gds super admin" do
      setup do
        @gds = create(:gds_organisation)
        @super_admin = create(:superadmin_user, organisation: @gds)
        @reason_for_exemption = "accessibility reasons"
        @expiry_date = 5.days.from_now.to_date
      end

      context "when the user being edited is not an admin or superadmin" do
        should "be able to exempt a user requiring 2sv from 2sv" do
          user_requiring_2sv = create(:two_step_mandated_user, organisation: @organisation)

          user_can_be_exempted_from_2sv(@super_admin, user_requiring_2sv, @reason_for_exemption, @expiry_date)
          assert_user_access_log_contains_messages(user_requiring_2sv, [exemption_message(@super_admin, @reason_for_exemption, @expiry_date)])
        end

        should "be able to exempt a user who does not yet require 2sv but is not exempt" do
          user_not_requiring_2sv = create(:user, organisation: @organisation)

          user_can_be_exempted_from_2sv(@super_admin, user_not_requiring_2sv, @reason_for_exemption, @expiry_date)
          assert_user_access_log_contains_messages(user_not_requiring_2sv, [exemption_message(@super_admin, @reason_for_exemption, @expiry_date)])
        end

        should "not be able to see a link to exempt a user who already has an exemption reason" do
          exempted_user = create(:two_step_exempted_user, organisation: @organisation)

          sign_in_as_and_edit_user(@super_admin, exempted_user)
          assert page.has_no_link? "Exempt user from 2-step verification"
        end

        should "not be able to exempt a user with an expiry date that is not in the future" do
          user_requiring_2sv = create(:two_step_mandated_user, organisation: @organisation)

          sign_in_as_and_edit_user(@super_admin, user_requiring_2sv)
          click_link("Exempt user from 2-step verification")
          fill_in_exemption_form(@reason_for_exemption, Time.zone.today.to_date)

          assert_user_has_not_been_exempted_from_2sv(user_requiring_2sv)
          assert page.has_text?("Expiry date must be in the future")
        end

        context "when a exemption reason already exists" do
          should "be able to edit exemption reason and date" do
            user_requiring_2sv = create(:user, organisation: @organisation, reason_for_2sv_exemption: "user is exempt", expiry_date_for_2sv_exemption: @expiry_date)

            sign_in_as_and_edit_user(@super_admin, user_requiring_2sv)
            click_link("Edit 2-step verification exemption")

            assert page.has_field?("Reason for 2-step verification exemption", with: "user is exempt")
            assert page.has_field?("Year", with: @expiry_date.year)
            assert page.has_field?("Month", with: @expiry_date.month)
            assert page.has_field?("Day", with: @expiry_date.day)

            new_expiry_date = 1.month.from_now.to_date
            fill_in_exemption_form(@reason_for_exemption, new_expiry_date)

            assert_user_has_been_exempted_from_2sv(user_requiring_2sv, @reason_for_exemption, new_expiry_date)

            assert_user_access_log_contains_messages(user_requiring_2sv, ["2-step verification exemption updated by #{@super_admin.name} to: #{@reason_for_exemption} expiring on date: #{new_expiry_date}"])
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
          user_requiring_2sv = create(:two_step_exempted_user, organisation: @organisation)

          sign_in_as_and_edit_user(@super_admin, user_requiring_2sv)

          assert page.has_text?(/2-step verification\s+Exempt/)
          assert page.has_no_link? "Edit 2-step verification exemption"
        end
      end
    end
  end
end
