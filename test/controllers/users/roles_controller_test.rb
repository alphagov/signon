require "test_helper"

class Users::RolesControllerTest < ActionController::TestCase
  context "GET edit" do
    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in(@superadmin)
      end

      should "display form with role field" do
        user = create(:user, role: Roles::Normal.role_name)

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_role_path(user)}']" do
          assert_select "select[name='user[role]'] option", value: Roles::Normal.role_name
          assert_select "input[type='submit']"
        end
      end

      should "not display role field if user is exempt from 2SV" do
        user = create(:two_step_exempted_user, role: Roles::Normal.role_name)

        get :edit, params: { user_id: user }

        assert_select "form[action='#{user_role_path(user)}']" do
          assert_select "select[name='user[role]'] option", count: 0
          assert_select "p", text: /their role cannot be changed/
        end
      end

      should "authorize access if UserPolicy#edit? and UserPolicy#assign_role? return true" do
        user = create(:user)

        user_policy = stub_everything("user-policy", edit?: true, assign_role?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_response :success
      end

      should "not authorize access if UserPolicy#edit? returns false" do
        user = create(:user)

        user_policy = stub_everything("user-policy", edit?: false, assign_role?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "not authorize access if UserPolicy#assign_role? returns false" do
        user = create(:user)

        user_policy = stub_everything("user-policy", edit?: true, assign_role?: false)
        UserPolicy.stubs(:new).returns(user_policy)

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
        user = create(:user_in_organisation, role: Roles::Normal.role_name)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.role_name } }

        assert_equal Roles::OrganisationAdmin.role_name, user.reload.role
      end

      should "record account updated & role change events" do
        user = create(:user_in_organisation, role: Roles::Normal.role_name)

        @controller.stubs(:user_ip_address).returns("1.1.1.1")

        EventLog.expects(:record_event).with(
          user,
          EventLog::ACCOUNT_UPDATED,
          initiator: @superadmin,
          ip_address: "1.1.1.1",
        )

        EventLog.expects(:record_role_change).with(
          user,
          Roles::Normal.role_name,
          Roles::OrganisationAdmin.role_name,
          @superadmin,
        )

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.role_name } }
      end

      should "should not record role change event if role has not changed" do
        user = create(:user, role: Roles::Normal.role_name)

        EventLog.expects(:record_role_change).never

        put :update, params: { user_id: user, user: { role: Roles::Normal.role_name } }
      end

      should "push changes out to apps" do
        user = create(:user_in_organisation)
        PermissionUpdater.expects(:perform_on).with(user).once

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.role_name } }
      end

      should "redirect to user page and display success notice" do
        user = create(:user_in_organisation, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.role_name } }

        assert_redirected_to edit_user_path(user)
        assert_equal "Updated user user@gov.uk successfully", flash[:notice]
      end

      should "update user role if UserPolicy#update? and UserPolicy#assign_role? return true" do
        user = create(:user_in_organisation, role: Roles::Normal.role_name)

        user_policy = stub_everything("user-policy", update?: true, assign_role?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.role_name } }

        assert_equal Roles::OrganisationAdmin.role_name, user.reload.role
      end

      should "not update user role if UserPolicy#update? returns false" do
        user = create(:user_in_organisation, role: Roles::Normal.role_name)

        user_policy = stub_everything("user-policy", update?: false, assign_role?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.role_name } }

        assert_equal Roles::Normal.role_name, user.reload.role
        assert_not_authorised
      end

      should "not update user role if UserPolicy#assign_role? returns false" do
        user = create(:user_in_organisation, role: Roles::Normal.role_name)

        user_policy = stub_everything("user-policy", update?: true, assign_role?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.role_name } }

        assert_equal Roles::Normal.role_name, user.reload.role
        assert_not_authorised
      end

      should "not update user role if user is exempt from 2SV" do
        user = create(:two_step_exempted_user, :in_organisation, role: Roles::Normal.role_name)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.role_name } }

        assert_equal Roles::Normal.role_name, user.reload.role

        assert_select ".govuk-error-summary" do
          assert_select "li", text: /#{Roles::OrganisationAdmin.role_name} users cannot be exempted from 2SV/
        end
      end

      should "redisplay form if role is not valid" do
        user = create(:user_in_organisation, role: Roles::Normal.role_name)

        put :update, params: { user_id: user, user: { role: "invalid-role" } }

        assert_template :edit
        assert_select "form[action='#{user_role_path(user)}']" do
          assert_select "select[name='user[role]'] option", value: Roles::Normal.role_name
        end
      end

      should "display errors if role is not valid" do
        user = create(:user_in_organisation)

        put :update, params: { user_id: user, user: { role: "invalid-role" } }

        assert_select ".govuk-error-summary" do
          assert_select "li", text: "Role is not included in the list"
        end
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user_in_organisation, role: Roles::Normal.role_name)

        put :update, params: { user_id: user, user: { role: Roles::OrganisationAdmin.role_name } }

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
