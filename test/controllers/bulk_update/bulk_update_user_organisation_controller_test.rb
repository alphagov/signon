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

    context "POST create" do
      should "return not authorised response" do
        post :create, params: {
          old_organisation_id: "1",
          new_organisation_id: "2",
        }

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

        assert_select "select[name='old_organisation_id']" do
          assert_select "option[value='#{@open_organisation.id}']", text: @open_organisation.name_with_abbreviation
          assert_select "option[value='#{@closed_organisation.id}']", text: @closed_organisation.name_with_abbreviation
        end
      end

      should "render form select for new organisation includes only open organisations" do
        get :index

        assert_select "select[name='new_organisation_id']" do
          assert_select "option[value='#{@open_organisation.id}']", text: @open_organisation.name_with_abbreviation
          refute_select "option[value='#{@closed_organisation.id}']"
        end
      end
    end

    context "POST update" do
      should "update user organisation when both organisations exist" do
        post :create, params: {
          old_organisation_id: @closed_organisation,
          new_organisation_id: @open_organisation,
        }

        assert_equal @user_from_closed_organisation.reload.organisation, @open_organisation

        assert_select "div.govuk-notification-banner__content h3", "Updated users"
        assert_select "div.govuk-notification-banner__content", /Moved 1 user from #{@closed_organisation.name} to #{@open_organisation.name}/
      end

      should "create an event log entry for the user when both organisations exist" do
        post :create, params: {
          old_organisation_id: @closed_organisation,
          new_organisation_id: @open_organisation,
        }

        latest_event_log = @user_from_closed_organisation.reload.event_logs.last
        assert_equal latest_event_log.event_id, EventLog::ORGANISATION_CHANGED.id
        assert_equal latest_event_log.trailing_message, "from #{@closed_organisation.name} to #{@open_organisation.name}"
      end

      should "show an error when the old organisation does not exist" do
        post :create, params: {
          old_organisation_id: (Organisation.pluck(:id).max + 1),
          new_organisation_id: @open_organisation,
        }

        assert_select "p.gem-c-error-alert__message", "Organisation does not exist"
      end

      should "show an error when the new organisation does not exist" do
        post :create, params: {
          old_organisation_id: @open_organisation,
          new_organisation_id: (Organisation.pluck(:id).max + 1),
        }

        assert_select "p.gem-c-error-alert__message", "Organisation does not exist"
      end

      should "show an error when the new and old organisations are the same" do
        post :create, params: {
          old_organisation_id: @open_organisation,
          new_organisation_id: @open_organisation,
        }

        assert_select "p.gem-c-error-alert__message", "Choose two different organisations"
      end

      should "show an error when the new organisations is closed" do
        post :create, params: {
          old_organisation_id: @open_organisation,
          new_organisation_id: @closed_organisation,
        }

        assert_select "p.gem-c-error-alert__message", "#{@closed_organisation.name} is closed and cannot receive users"
      end

      should "show an error when a user fails validation" do
        User.any_instance.stubs(:update!).raises(
          ActiveRecord::RecordInvalid.new(@user_from_closed_organisation),
        )

        post :create, params: {
          old_organisation_id: @closed_organisation,
          new_organisation_id: @open_organisation,
        }

        assert_select "p.gem-c-error-alert__message", "Failed to update user: #{@user_from_closed_organisation.email}"
        refute_select "div.govuk-notification-banner__content h3", "Updated users"
      end

      should "roll back all user updates and not show a success message when a user fails validation part-way through" do
        second_user = create(:user, organisation: @closed_organisation)
        EventLog.stubs(:record_organisation_change).returns(nil).then.raises(
          ActiveRecord::RecordInvalid.new(second_user),
        )

        post :create, params: {
          old_organisation_id: @closed_organisation,
          new_organisation_id: @open_organisation,
        }

        assert_equal @closed_organisation, @user_from_closed_organisation.reload.organisation
        assert_equal @closed_organisation, second_user.reload.organisation
        assert_select "p.gem-c-error-alert__message", "Failed to update user: #{second_user.email}"
        refute_select "div.govuk-notification-banner__content h3", "Updated users"
      end

      should "roll back and show an error when the event log fails validation" do
        EventLog.stubs(:record_organisation_change).raises(
          ActiveRecord::RecordInvalid.new(EventLog.new),
        )

        post :create, params: {
          old_organisation_id: @closed_organisation,
          new_organisation_id: @open_organisation,
        }

        assert_equal @closed_organisation, @user_from_closed_organisation.reload.organisation
        assert_select "p.gem-c-error-alert__message", "Failed to record the organisation change"
        refute_select "div.govuk-notification-banner__content h3", "Updated users"
      end
    end
  end
end
