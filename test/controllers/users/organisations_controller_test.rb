require "test_helper"

class Users::OrganisationsControllerTest < ActionController::TestCase
  attr_reader :organisation

  setup do
    @organisation = create(:organisation)
  end

  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "display form with organisation_id field" do
        user = create(:user, organisation:)

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_organisation_path(user)}']" do
          assert_select "select[name='user[organisation_id]'] option", value: organisation.id
          assert_select "button[type='submit']", text: "Change organisation"
          assert_select "a[href='#{edit_user_path(user)}']", text: "Cancel"
        end
      end

      should "authorize access if UserPolicy#assign_organisation? returns true" do
        user = create(:user)

        stub_policy(@admin, user, assign_organisation?: true)
        stub_policy_for_navigation_links(@admin)

        get :edit, params: { user_id: user }

        assert_response :success
      end

      should "not authorize access if UserPolicy#assign_organisation? returns false" do
        user = create(:user)

        stub_policy(@admin, user, assign_organisation?: false)
        stub_policy_for_navigation_links(@admin)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "redirect to account edit organisation page if admin is acting on their own user" do
        get :edit, params: { user_id: @admin }

        assert_redirected_to edit_account_organisation_path
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end

  context "PUT update" do
    attr_reader :another_organisation

    setup do
      @another_organisation = create(:organisation)
    end

    context "signed in as Admin user" do
      setup do
        @admin = create(:admin_user)
        sign_in(@admin)
      end

      should "update user organisation" do
        user = create(:user, organisation:)

        put :update, params: { user_id: user, user: { organisation_id: another_organisation } }

        assert_equal another_organisation, user.reload.organisation
      end

      should "record account updated & organisation change events" do
        user = create(:user, organisation:)

        EventLog.expects(:record_event).with(
          user,
          EventLog::ACCOUNT_UPDATED,
          initiator: true,
          ip_address: true,
        )

        EventLog.expects(:record_organisation_change).with(
          user,
          organisation.name,
          another_organisation.name,
        )

        put :update, params: { user_id: user, user: { organisation_id: another_organisation } }
      end

      should "should not record organisation change event if organisation has not changed" do
        user = create(:user, organisation:)

        EventLog.expects(:record_organisation_change).never

        put :update, params: { user_id: user, user: { organisation_id: organisation } }
      end

      should "push changes out to apps" do
        user = create(:user, organisation:)

        PermissionUpdater.expects(:perform_on).with(user)

        put :update, params: { user_id: user, user: { organisation_id: another_organisation } }
      end

      should "redirect to user page and display success notice" do
        user = create(:user, organisation:, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { organisation_id: another_organisation } }

        assert_redirected_to edit_user_path(user)
        assert_equal "Updated user user@gov.uk successfully", flash[:notice]
      end

      should "update user organisation if UserPolicy#assign_organisation? returns true" do
        user = create(:user, organisation:)

        stub_policy(@admin, user, assign_organisation?: true)

        put :update, params: { user_id: user, user: { organisation_id: another_organisation } }

        assert_equal another_organisation, user.reload.organisation
      end

      should "not update user organisation if UserPolicy#assign_organisation? returns false" do
        user = create(:user, organisation:)

        stub_policy(@admin, user, assign_organisation?: false)

        put :update, params: { user_id: user, user: { organisation_id: another_organisation } }

        assert_equal organisation, user.reload.organisation
        assert_not_authorised
      end

      should "redisplay form if organisation is not valid" do
        user = create(:organisation_admin_user, organisation:)

        put :update, params: { user_id: user, user: { organisation_id: nil } }

        assert_template :edit
        assert_select "form[action='#{user_organisation_path(user)}']" do
          assert_select "select[name='user[organisation_id]'] option", value: organisation.id
        end
      end

      should "display errors if organisation is not valid" do
        user = create(:organisation_admin_user, organisation:)

        put :update, params: { user_id: user, user: { organisation_id: nil } }

        assert_select ".govuk-error-summary" do
          assert_select "a", href: "#user_organisation_id", text: "Organisation can't be 'None' for Organisation admin"
        end
        assert_select ".govuk-form-group" do
          assert_select ".govuk-error-message", text: "Error: Organisation can't be 'None' for Organisation admin"
          assert_select "select[name='user[organisation_id]'].govuk-select--error"
        end
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user, organisation:)

        put :update, params: { user_id: user, user: { organisation_id: another_organisation } }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user, organisation:)

        put :update, params: { user_id: user, user: { organisation_id: another_organisation } }

        assert_not_authenticated
      end
    end
  end
end
