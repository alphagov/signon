require "test_helper"

class ExemptFromTwoStepVerificationTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ActiveJob::TestHelper

  def sign_in_as_and_edit_user(sign_in_as, user_to_edit)
    visit root_path
    signin_with(sign_in_as)
    visit edit_user_path(user_to_edit)
  end

  context "when logged in as a gds super admin" do
    setup do
      @gds = create(:organisation, content_id: Organisation::GDS_ORG_CONTENT_ID)
      @super_admin = create(:superadmin_user, organisation: @gds)
      @reason_for_exemption = "accessibility reasons"
    end

    should "be able to see a link to exempt a user requiring 2sv from 2sv" do
      user_requiring_2sv = create(:two_step_mandated_user, organisation: @organisation)

      sign_in_as_and_edit_user(@super_admin, user_requiring_2sv)
      click_link("Exempt user from 2-step verification")

      fill_in "Reason for 2sv exemption", with: @reason_for_exemption
      click_button "Save"

      user_requiring_2sv.reload

      assert_not user_requiring_2sv.require_2sv?
      assert_equal @reason_for_exemption, user_requiring_2sv.reason_for_2sv_exemption

      assert page.has_text? "User exempted from 2SV"
    end

    should "be able to see a link to exempt a user who does not yet require 2sv but is not exempt" do
      user_not_requiring_2sv = create(:user, organisation: @organisation)

      sign_in_as_and_edit_user(@super_admin, user_not_requiring_2sv)
      click_link("Exempt user from 2-step verification")

      fill_in "Reason for 2sv exemption", with: @reason_for_exemption
      click_button "Save"

      user_not_requiring_2sv.reload

      assert_not user_not_requiring_2sv.require_2sv?
      assert_equal @reason_for_exemption, user_not_requiring_2sv.reason_for_2sv_exemption

      assert page.has_text? "User exempted from 2SV"
    end

    should "not be able to see a link to exempt a user who already has an exemption reason" do
      exempted_user = create(:two_step_exempted_user, organisation: @organisation)

      sign_in_as_and_edit_user(@super_admin, exempted_user)
      assert page.has_no_link? "Exempt user from 2-step verification"
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
  end
end
