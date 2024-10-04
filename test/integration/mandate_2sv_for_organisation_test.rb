require "test_helper"

class Mandate2svForOrganisationTest < ActionDispatch::IntegrationTest
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
          within two_step_verification_cell_for_organisation(@organisation.slug) do
            assert assert_text "false"
          end
        end

        should "be able to edit organisation 2sv status" do
          click_edit_2sv_button_for(@organisation.slug)
          check "Mandate 2-step verification for #{@organisation.name}"
          click_button "Update organisation"
          assert page.has_text? "true"
        end
      end

      context "organisation mandates 2sv" do
        setup do
          @organisation = create(:organisation, require_2sv: true)
          visit organisations_path
        end

        should "be able to see organisation 2sv status" do
          within two_step_verification_cell_for_organisation(@organisation.slug) do
            assert assert_text "true"
          end
        end

        should "be able to edit organisation 2sv status" do
          click_edit_2sv_button_for(@organisation.slug)
          uncheck "Mandate 2-step verification for #{@organisation.name}"
          click_button "Update organisation"
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
        within two_step_verification_cell_for_organisation(@organisation.slug) do
          assert assert_text "false"
        end
      end

      should "not be able to see the edit link" do
        assert page.has_no_link? "Edit"
      end

      should "not be able to edit organisation 2sv status" do
        visit edit_organisation_path(@organisation)
        assert page.has_text?("You do not have permission to perform this action.")
        assert_equal "/", current_path
      end
    end
  end

  def click_edit_2sv_button_for(organisation_slug)
    edit_link = two_step_verification_cell_for_organisation(organisation_slug).find_link(text: "Edit")
    edit_link.click
  end

  def two_step_verification_cell_for_organisation(organisation_slug)
    active_organisations_table_container = find "#active"
    slug_column_index = index_of_column_with_header("Slug")
    two_step_verification_column_index = index_of_column_with_header("2-step verification mandated?")

    organisation_row = active_organisations_table_container
      .find(:css, "tbody")
      .all(:css, "tr")
      .map { |row| row.all(:css, "td") }
      .find { |row| row[slug_column_index].text == organisation_slug }

    organisation_row[two_step_verification_column_index]
  end

  def index_of_column_with_header(column_name)
    page.all(:css, "th").map(&:text).find_index(column_name)
  end
end
