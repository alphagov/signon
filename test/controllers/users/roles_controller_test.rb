require "test_helper"

class Users::RolesControllerTest < ActionController::TestCase
  context "GET edit" do
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in(@superadmin)
      end

      should "display form with role field" do
        user = create(:user, role: Roles::Normal.name)

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_role_path(user)}']" do
          assert_select "select[name='user[role]'] option", value: Roles::Normal.name
          assert_select "button[type='submit']", text: "Change role"
          assert_select "a[href='#{edit_user_path(user)}']", text: "Cancel"
        end
      end

      should "not display form if user is exempt from 2SV" do
        user = create(:two_step_exempted_user, role: Roles::Normal.name)

        get :edit, params: { user_id: user }

        assert_select "form[action='#{user_role_path(user)}']" do
          assert_select "select[name='user[role]'] option", count: 0
          assert_select ".govuk-inset-text", text: /their role cannot be changed/
        end
      end

      should "authorize access if UserPolicy#assign_role? returns true" do
        user = create(:user)

        stub_policy(@superadmin, user, assign_role?: true)
        stub_policy_for_navigation_links(@superadmin)

        get :edit, params: { user_id: user }

        assert_response :success
      end

      should "not authorize access if UserPolicy#assign_role? returns false" do
        user = create(:user)

        stub_policy(@superadmin, user, assign_role?: false)
        stub_policy_for_navigation_links(@superadmin)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "redirect to account edit role page if admin is acting on their own user" do
        get :edit, params: { user_id: @superadmin }

        assert_redirected_to edit_account_role_path
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
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in(@superadmin)
      end

      should "update user role" do
        user = create(:user_in_organisation, role: Roles::Normal.name)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.name } }

        assert_equal Roles::OrganisationAdmin, user.reload.role
      end

      should "record account updated & role change events" do
        user = create(:user_in_organisation, role: Roles::Normal.name)

        EventLog.expects(:record_event).with(
          user,
          EventLog::ACCOUNT_UPDATED,
          initiator: @superadmin,
          ip_address: true,
        )

        EventLog.expects(:record_role_change).with(
          user,
          Roles::Normal.name,
          Roles::OrganisationAdmin.name,
        )

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.name } }
      end

      should "should not record role change event if role has not changed" do
        user = create(:user, role: Roles::Normal.name)

        EventLog.expects(:record_role_change).never

        put :update, params: { user_id: user, user: { role: Roles::Normal.name } }
      end

      should "push changes out to apps" do
        user = create(:user_in_organisation)
        PermissionUpdater.expects(:perform_on).with(user)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.name } }
      end

      should "redirect to user page and display success notice" do
        user = create(:user_in_organisation, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.name } }

        assert_redirected_to edit_user_path(user)
        assert_equal "Updated user user@gov.uk successfully", flash[:notice]
      end

      should "update user role if UserPolicy#assign_role? returns true" do
        user = create(:user_in_organisation, role: Roles::Normal.name)

        stub_policy(@superadmin, user, assign_role?: true)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.name } }

        assert_equal Roles::OrganisationAdmin, user.reload.role
      end

      should "not update user role if UserPolicy#assign_role? returns false" do
        user = create(:user_in_organisation, role: Roles::Normal.name)

        stub_policy(@superadmin, user, assign_role?: false)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.name } }

        assert_equal Roles::Normal, user.reload.role
        assert_not_authorised
      end

      should "not update user role if user is exempt from 2SV" do
        user = create(:two_step_exempted_user, :in_organisation, role: Roles::Normal.name)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.name } }

        assert_equal Roles::Normal, user.reload.role

        assert_select ".govuk-error-summary" do
          assert_select "li", text: /cannot be blank for #{Roles::OrganisationAdmin.name.humanize} users/
        end
      end

      should "redisplay form if role is not valid" do
        user = create(:user_in_organisation, role: Roles::Normal.name)

        put :update, params: { user_id: user, user: { role: "invalid-role" } }

        assert_template :edit
        assert_select "form[action='#{user_role_path(user)}']" do
          assert_select "select[name='user[role]'] option", value: Roles::Normal.name
        end
      end

      should "display errors if role is not valid" do
        user = create(:user_in_organisation)

        put :update, params: { user_id: user, user: { role: "invalid-role" } }

        assert_select ".govuk-error-summary" do
          assert_select "a", href: "#user_role", text: "Role is not included in the list"
        end
        assert_select ".govuk-form-group" do
          assert_select ".govuk-error-message", text: "Error: Role is not included in the list"
          assert_select "select[name='user[role]'].govuk-select--error"
        end
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user_in_organisation, role: Roles::Normal.name)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.name } }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user_in_organisation)

        get :update, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end
end
