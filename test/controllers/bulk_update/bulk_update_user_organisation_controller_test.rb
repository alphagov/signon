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
      @user_from_closed_organisation = create(:user, organisation: @closed_organisation)
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

    context "PATCH update" do
      should "update user organisation when both organisations exist" do
        patch :update, params: {
          old_organisation_id: @closed_organisation,
          new_organisation_id: @open_organisation,
        }

        assert_equal @user_from_closed_organisation.reload.organisation, @open_organisation

        assert_select "div.govuk-notification-banner__content h3", "Updated users"
        assert_select "div.govuk-notification-banner__content", /Moved 1 users from #{@closed_organisation.name} to #{@open_organisation.name}/
      end

      should "create an event log entry for the user when both organisations exist" do
        patch :update, params: {
          old_organisation_id: @closed_organisation,
          new_organisation_id: @open_organisation,
        }

        latest_event_log = @user_from_closed_organisation.reload.event_logs.last
        assert_equal latest_event_log.event_id, EventLog::ORGANISATION_CHANGED.id
        assert_equal latest_event_log.trailing_message, "from #{@closed_organisation.name} to #{@open_organisation.name}"
      end

      should "show an error when the old organisation does not exist" do
        patch :update, params: {
          old_organisation_id: (Organisation.pluck(:id).max + 1),
          new_organisation_id: @open_organisation,
        }

        assert_select "p.gem-c-error-alert__message", "Organisation does not exist"
      end

      should "show an error when the new organisation does not exist" do
        patch :update, params: {
          old_organisation_id: @open_organisation,
          new_organisation_id: (Organisation.pluck(:id).max + 1),
        }

        assert_select "p.gem-c-error-alert__message", "Organisation does not exist"
      end
    end
  end
end
