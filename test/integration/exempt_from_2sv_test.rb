require "test_helper"

class ExemptFromTwoStepVerificationTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ActiveJob::TestHelper

  def sign_in_as_and_edit_user(sign_in_as, user_to_edit)
    visit root_path
    signin_with(sign_in_as)
    visit edit_user_path(user_to_edit)
  end

  def assert_access_log_updated_with_exemption(initiator_name, reason)
    click_link "Account access log"

    assert page.has_text? "Exempted from 2-step verification by #{initiator_name} for reason: #{reason}"
  end

  def assert_user_can_be_exempted_from_2sv(signed_in_as, user_being_exempted, reason)
    sign_in_as_and_edit_user(signed_in_as, user_being_exempted)
    click_link("Exempt user from 2-step verification")

    fill_in "Reason for 2sv exemption", with: reason
    click_button "Save"

    assert_user_has_been_exempted_from_2sv(user_being_exempted, reason)
  end

  def assert_user_has_been_exempted_from_2sv(user, reason)
    user.reload

    assert_not user.require_2sv?
    assert_equal reason, user.reason_for_2sv_exemption

    assert page.has_text? "User exempted from 2SV"
    assert page.has_text? "The user has been made exempt from 2-step verification for the following reason: #{reason}"
  end

  context "when logged in as a gds super admin" do
    setup do
      @gds = create(:organisation, content_id: Organisation::GDS_ORG_CONTENT_ID)
      @super_admin = create(:superadmin_user, organisation: @gds)
      @reason_for_exemption = "accessibility reasons"
    end

    context "when the user being edited is not an admin or superadmin" do
      should "be able to see a link to exempt a user requiring 2sv from 2sv" do
        user_requiring_2sv = create(:two_step_mandated_user, organisation: @organisation)

        assert_user_can_be_exempted_from_2sv(@super_admin, user_requiring_2sv, @reason_for_exemption)
        assert_access_log_updated_with_exemption(@super_admin.name, @reason_for_exemption)
      end

      should "be able to see a link to exempt a user who does not yet require 2sv but is not exempt" do
        user_not_requiring_2sv = create(:user, organisation: @organisation)

        assert_user_can_be_exempted_from_2sv(@super_admin, user_not_requiring_2sv, @reason_for_exemption)
        assert_access_log_updated_with_exemption(@super_admin.name, @reason_for_exemption)
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

          click_link "Account access log"

          assert page.has_text? "Reason for 2-step verification exemption updated by #{@super_admin.name} to: #{@reason_for_exemption}"
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
