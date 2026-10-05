require "test_helper"

class BulkUpdate::CloseOrganisationControllerTest < ActionController::TestCase
  context "as admin user" do
    setup do
      @admin = create(:admin_user)
      sign_in @admin
    end

    context "GET index" do
      should "return not authorised response" do
        get :index

        assert_not_authorised
      end
    end
  end

  context "as superadmin" do
    setup do
      @superadmin = create(:superadmin_user)
      @open_organisation = create(:organisation)
      @closed_organisation = create(:organisation, closed: true)
      sign_in @superadmin
    end

    context "GET index" do
      should "render form select for organisation with all open organisations included" do
        get :index

        assert_select "form" do
          assert_select "select[name='organisation_id']"
          assert_select "option[value='#{@open_organisation.id}']", text: @open_organisation.name
          refute_select "option[value='#{@closed_organisation.id}']", text: @closed_organisation.name
        end
      end
    end

    context "PATCH update" do
      should "mark as closed when organisation exists" do
        patch :update, params: { organisation_id: @open_organisation }

        assert @open_organisation.reload.closed?

        assert_select "div.govuk-notification-banner__content h3", "Organisation closed"
        assert_select "div.govuk-notification-banner__content", /#{@open_organisation.name} has been marked as closed/
      end

      should "show an error when organisation does not exist" do
        patch :update, params: { organisation_id: (Organisation.pluck(:id).max + 1) }

        assert_select "p.gem-c-error-alert__message", "Organisation does not exist"
      end
    end
  end
end
