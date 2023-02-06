require "test_helper"

class Mandate2svForOrganisationTest < ActionDispatch::IntegrationTest
  include HtmlTableHelpers

  context "Changing 2sv status of an Organisation" do
    context "when logged in as a super admin" do
      setup do
        @super_admin = create(:superadmin_user)
        visit root_path
        signin_with(@super_admin)
      end

      context "organisation does not currently mandate 2sv" do
        setup do
          @organisation = create(:organisation, require_2sv: false)
          visit organisations_path
        end

        should "be able to see organisation 2sv status" do
          assert_displayed_organisation_has_2sv_status(@organisation, "false")
        end

        should "be able to edit organisation 2sv status" do
          visit edit_organisation_path(@organisation)
          check "Mandate 2-step verification for #{@organisation.name}"
          click_button "Update Organisation"
          assert page.has_text? "true"
        end
      end

      context "organisation mandates 2sv" do
        setup do
          @organisation = create(:organisation, require_2sv: true)
          visit organisations_path
        end

        should "be able to see organisation 2sv status" do
          assert_displayed_organisation_has_2sv_status(@organisation, "true")
        end

        should "be able to edit organisation 2sv status" do
          visit edit_organisation_path(@organisation)
          uncheck "Mandate 2-step verification for #{@organisation.name}"
          click_button "Update Organisation"
          assert page.has_text? "false"
        end
      end
    end

    context "when logged in as an admin" do
      setup do
        @admin = create(:admin_user)
        visit root_path
        signin_with(@admin)
        @organisation = create(:organisation, require_2sv: false)
        visit organisations_path
      end

      should "be able to see organisation 2sv status" do
        assert_displayed_organisation_has_2sv_status(@organisation, "false")
      end

      should "not be able to edit organisation 2sv status" do
        visit edit_organisation_path(@organisation)
        assert page.has_text?("You do not have permission to perform this action.")
        assert_equal "/", current_path
      end
    end
  end

  def assert_displayed_organisation_has_2sv_status(organisation, expected)
    organisation_row = find_row_by_column_contents("Slug", organisation.slug)
    two_step_verification_column = index_of_column_with_header("2-step verification mandated?")
    assert organisation_row && organisation_row[two_step_verification_column].text.include?(expected)
  end
end
