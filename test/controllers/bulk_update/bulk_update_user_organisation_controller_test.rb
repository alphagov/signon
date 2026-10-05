require "test_helper"

class BulkUpdate::BulkUpdateUserOrganisationControllerTest < ActionController::TestCase
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
      should "render form select for old organisation includes all organisations" do
        get :index

        assert_select "form" do
          assert_select "select[name='old_organisation_id'] option[value='#{@open_organisation.id}']", text: @open_organisation.name
          refute_select "select[name='old_organisation_id'] option[value='#{@closed_organisation.id}']", text: @closed_organisation.name
        end
      end

      should "render form select for new organisation includes only open organisations" do
        get :index

        assert_select "form" do
          assert_select "select[name='new_organisation_id'] option[value='#{@open_organisation.id}']", text: @open_organisation.name
          refute_select "select[name='new_organisation_id'] option[value='#{@closed_organisation.id}']", text: @closed_organisation.name
        end
      end
    end
  end
end
