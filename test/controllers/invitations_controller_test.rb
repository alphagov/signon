require "test_helper"

class InvitationsControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  context "GET new" do
    context "when inviter is signed in as an admin" do
      setup do
        sign_in create(:admin_user)
      end

      should "allow access" do
        get :new

        assert_template :new
      end

      should "render form with action pointing at create action" do
        get :new

        assert_select "form[action='#{user_invitation_path}']"
      end

      should "render form text inputs for name & email" do
        get :new

        assert_select "form" do
          assert_select "input[name='user[name]']"
          assert_select "input[name='user[email]']"
        end
      end

      should "not render form select for role" do
        get :new

        assert_select "form" do
          assert_select "select[name='user[role]']", count: 0
        end
      end

      should "render form select for organisation" do
        get :new

        assert_select "form" do
          assert_select "select[name='user[organisation_id]']"
        end
      end

      should "render form checkbox inputs for permissions" do
        application = create(:application)
        signin_permission = application.signin_permission
        other_permission = create(:supported_permission)

        get :new

        assert_select "form" do
          assert_select "input[type='checkbox'][name='user[supported_permission_ids][]'][value='#{signin_permission.to_param}']"
          assert_select "input[type='checkbox'][name='user[supported_permission_ids][]'][value='#{other_permission.to_param}']"
        end
      end

      should "render form checkbox inputs with some default permissions checked" do
        application = create(:application)
        permission = create(:supported_permission, default: true, application:)

        get :new

        assert_select "form" do
          assert_select "input[type='checkbox'][checked='checked'][name='user[supported_permission_ids][]'][value='#{permission.to_param}']"
        end
      end

      should "render filter for option-select component when app has more than 4 permissions" do
        application = create(:application)
        4.times { create(:supported_permission, application:) }
        assert application.supported_permissions.count > 4

        get :new

        assert_select "form" do
          assert_select ".gem-c-option-select[data-filter-element]"
        end
      end

      should "not render form checkbox inputs for permissions for API-only applications" do
        application = create(:application, api_only: true)
        signin_permission = application.signin_permission

        get :new

        assert_select "form" do
          assert_select "input[type='checkbox'][name='user[supported_permission_ids][]'][value='#{signin_permission.to_param}']", count: 0
        end
      end

      should "not render form checkbox inputs for permissions for retired applications" do
        application = create(:application, retired: true)
        signin_permission = application.signin_permission

        get :new

        assert_select "form" do
          assert_select "input[type='checkbox'][name='user[supported_permission_ids][]'][value='#{signin_permission.to_param}']", count: 0
        end
      end
    end

    context "when inviter is signed in as a superadmin" do
      setup do
        sign_in create(:superadmin_user)
      end

      should "allow access" do
        get :new

        assert_template :new
      end

      should "render form select for role" do
        get :new

        assert_select "form" do
          assert_select "select[name='user[role]']"
        end
      end
    end

    context "when inviter is signed in as a normal (non-admin) user" do
      setup do
        sign_in create(:user)
      end

      should "disallow access" do
        get :new

        assert_not_authorised
      end
    end

    context "when inviter is signed in as an organisation admin" do
      setup do
        sign_in create(:organisation_admin_user)
      end

      should "disallow access" do
        get :new

        assert_not_authorised
      end
    end

    context "when inviter is signed in as a super organisation admin" do
      setup do
        sign_in create(:super_organisation_admin_user)
      end

      should "disallow access" do
        get :new

        assert_not_authorised
      end
    end

    context "when inviter is not signed in" do
      should "require inviter to be signed in" do
        get :new

        assert_not_authenticated
      end
    end
  end

  context "POST create" do
    context "when inviter is signed in as a superadmin" do
      setup do
        @organisation = create(:organisation)
        @inviter = create(:superadmin_user)
        sign_in @inviter
      end

      should "save invitee with permitted attributes" do
        permission = create(:supported_permission)

        post :create, params: {
          user: {
            name: "invitee",
            email: "invitee@gov.uk",
            organisation_id: @organisation,
            role: Roles::OrganisationAdmin.role_name,
            supported_permission_ids: [permission.to_param],
          },
        }

        invitee = User.last
        assert invitee.present?
        assert_equal "invitee", invitee.name
        assert_equal "invitee@gov.uk", invitee.email
        assert_equal @organisation, invitee.organisation
        assert_equal Roles::OrganisationAdmin.role_name, invitee.role
        assert_equal [permission], invitee.supported_permissions
      end

      should "send invitation to invitee from inviter" do
        invitee = create(:user)
        User.expects(:invite!).with(anything, @inviter).returns(invitee)

        post :create, params: { user: { name: "invitee", email: "invitee@gov.uk", organisation_id: @organisation } }
      end

      context "and invitee will be assigned to organisation not requiring 2SV" do
        setup do
          @organisation = create(:organisation, require_2sv: false)
        end

        should "set require_2sv on invitee to false" do
          post :create, params: { user: { name: "invitee", email: "invitee@gov.uk", organisation_id: @organisation } }

          assert_not User.last.require_2sv?
        end

        should "render 2SV form allowing inviter to choose whether to require 2SV" do
          post :create, params: { user: { name: "invitee", email: "invitee@gov.uk", organisation_id: @organisation } }

          assert_redirected_to require_2sv_user_path(User.last)
        end

        context "when invitee role is set to superadmin" do
          setup do
            @role = Roles::Superadmin.role_name
          end

          should "set require_2sv on invitee to true" do
            post :create, params: { user: { name: "superadmin-invitee", email: "superadmin-invitee@gov.uk", organisation_id: @organisation, role: @role } }

            assert User.last.require_2sv?
          end

          should "not render 2SV form, because superadmins must use 2SV" do
            post :create, params: { user: { name: "superadmin-invitee", email: "superadmin-invitee@gov.uk", organisation_id: @organisation, role: @role } }

            assert_redirected_to users_path
          end
        end

        context "when invitee role is set to admin" do
          setup do
            @role = Roles::Admin.role_name
          end

          should "set require_2sv on invitee to true" do
            post :create, params: { user: { name: "admin-invitee", email: "admin-invitee@gov.uk", organisation_id: @organisation, role: @role } }

            assert User.last.require_2sv?
          end

          should "not render 2SV form, because admins must use 2SV" do
            post :create, params: { user: { name: "admin-invitee", email: "admin-invitee@gov.uk", organisation_id: @organisation, role: @role } }

            assert_redirected_to users_path
          end
        end

        context "when invitee role is set to organisation admin" do
          setup do
            @role = Roles::OrganisationAdmin.role_name
          end

          should "set require_2sv on invitee to true" do
            post :create, params: { user: { name: "org-admin-invitee", email: "org-admin-invitee@gov.uk", organisation_id: @organisation, role: @role } }

            assert User.last.require_2sv?
          end

          should "not render 2SV form, because organisation admins must use 2SV" do
            post :create, params: { user: { name: "org-admin-invitee", email: "org-admin-invitee@gov.uk", organisation_id: @organisation, role: @role } }

            assert_redirected_to users_path
          end
        end

        context "when invitee role is set to super organisation admin" do
          setup do
            @role = Roles::SuperOrganisationAdmin.role_name
          end

          should "set require_2sv on invitee to true" do
            post :create, params: { user: { name: "super-org-admin-invitee", email: "super-org-admin-invitee@gov.uk", organisation_id: @organisation, role: @role } }

            assert User.last.require_2sv?
          end

          should "not render 2SV form, because super organisation admins must use 2SV" do
            post :create, params: { user: { name: "super-org-admin-invitee", email: "super-org-admin-invitee@gov.uk", organisation_id: @organisation, role: @role } }

            assert_redirected_to users_path
          end
        end
      end

      context "and invitee will be assigned to organisation requiring 2SV" do
        setup do
          @organisation = create(:organisation, require_2sv: true)
        end

        should "set require_2sv on invitee to true" do
          post :create, params: { user: { name: "invitee", email: "invitee@gov.uk", organisation_id: @organisation } }

          invitee = User.last
          assert invitee.require_2sv?
        end

        should "not render 2SV form allowing inviter to choose whether to require 2SV" do
          post :create, params: { user: { name: "invitee", email: "invitee@gov.uk", organisation_id: @organisation } }

          assert_redirected_to users_path
          assert_equal "invitee", User.last.name
        end
      end

      should "re-render form and not save invitee if there are validation errors" do
        post :create, params: { user: { name: "invitee-without-email", email: "" } }

        assert_template :new
        assert_not User.exists?(name: "invitee-without-email")
      end

      should "keep name value if there are validation errors" do
        post :create, params: { user: { name: "invitee" } }

        assert_select "form" do
          assert_select "input[name='user[name]'][value='invitee']"
        end
      end

      should "keep email value if there are validation errors" do
        post :create, params: { user: { email: "invitee@gov.uk" } }

        assert_select "form" do
          assert_select "input[name='user[email]'][value='invitee@gov.uk']"
        end
      end

      should "keep selected organisation & role if there are validation errors" do
        post :create, params: { user: { organisation_id: @organisation, role: Roles::Admin.role_name } }

        assert_select "form" do
          assert_select "select[name='user[organisation_id]']" do
            assert_select "option[value='#{@organisation.to_param}'][selected]"
          end
          assert_select "select[name='user[role]']" do
            assert_select "option[value='#{Roles::Admin.role_name}'][selected]"
          end
        end
      end

      should "keep selected permissions if there are validation errors" do
        application = create(:application)
        signin_permission = application.signin_permission
        other_permission = create(:supported_permission)
        selected_permissions = [signin_permission, other_permission]

        post :create, params: { user: { supported_permission_ids: selected_permissions.map(&:to_param) } }

        assert_select "form" do
          assert_select "input[type='checkbox'][name='user[supported_permission_ids][]'][value='#{signin_permission.to_param}'][checked]"
          assert_select "input[type='checkbox'][name='user[supported_permission_ids][]'][value='#{other_permission.to_param}'][checked]"
        end
      end

      should "put selected permissions at the top if there are validation errors" do
        application = create(:application)
        signin_permission = application.signin_permission
        other_permission = create(:supported_permission, application:)
        selected_permissions = [other_permission]

        post :create, params: { user: { supported_permission_ids: selected_permissions.map(&:to_param) } }

        assert_select "form #user_application_#{application.id}_supported_permissions" do
          assert_select "input[type='checkbox'][name='user[supported_permission_ids][]']" do |checkboxes|
            assert_equal other_permission.to_param, checkboxes.first["value"]
            assert_equal signin_permission.to_param, checkboxes.last["value"]
          end
        end
      end

      should "record account invitation in event log when invitation sent" do
        EventLog.expects(:record_account_invitation).with(instance_of(User))

        post :create, params: { user: { name: "invitee", email: "invitee@gov.uk" } }
      end

      should "not record account invitation in event log when invitation not sent because of validation errors" do
        EventLog.expects(:record_account_invitation).never

        post :create, params: { user: { name: "invitee-without-email", email: "" } }
      end

      should "not record account invitation in event log when invitation not sent because user already exists" do
        existing_user = create(:user)

        EventLog.expects(:record_account_invitation).never

        post :create, params: { user: { name: existing_user.name, email: existing_user.email } }
      end

      should "not allow creation of api users" do
        post :create, params: { user: { name: "api-invitee", email: "api-invitee@gov.uk", api_user: true } }

        assert_empty User.where(api_user: true)
      end

      should "redirect to users page and display flash alert when inviting an existing user" do
        existing_user = create(:user)

        post :create, params: { user: { name: existing_user.name, email: existing_user.email } }

        assert_redirected_to users_path
        assert_equal "User already invited. If you want to, you can click 'Resend signup email'.", flash[:alert]
      end
    end

    context "when inviter is signed in as an admin" do
      setup do
        @organisation = create(:organisation)
        sign_in create(:admin_user)
      end

      should "ignore role param when saving invitee" do
        post :create, params: {
          user: {
            name: "invitee",
            email: "invitee@gov.uk",
            organisation_id: @organisation,
            role: Roles::OrganisationAdmin.role_name,
          },
        }

        invitee = User.last
        assert invitee.present?
        default_role = Roles::Normal.role_name
        assert_equal default_role, invitee.role
      end
    end

    context "when inviter is signed in as a normal (non-admin) user" do
      setup do
        sign_in create(:user)
      end

      should "disallow access" do
        post :create, params: { user: { name: "invitee", email: "invitee@gov.uk" } }

        assert_not_authorised
      end
    end

    context "when inviter is signed in as an organisation admin" do
      setup do
        sign_in create(:organisation_admin_user)
      end

      should "disallow access" do
        post :create, params: { user: { name: "org-admin-invitee", email: "org-admin-invitee@gov.uk" } }

        assert_not_authorised
      end
    end

    context "when inviter is signed in as a super organisation admin" do
      setup do
        sign_in create(:super_organisation_admin_user)
      end

      should "disallow access" do
        post :create, params: { user: { name: "super-org-admin-invitee", email: "super-org-admin-invitee@gov.uk" } }

        assert_not_authorised
      end
    end

    context "when inviter is not signed in" do
      should "require inviter to be signed in" do
        post :create

        assert_not_authenticated
      end
    end
  end

  context "GET edit" do
    setup do
      @invitee = User.invite!(attributes_for(:user))
      @token = @invitee.raw_invitation_token
    end

    should "render form for setting password" do
      get :edit, params: { invitation_token: @token }

      assert_template :edit
      assert_select "form[action='#{user_invitation_path}']" do
        assert_select "input[type='password'][name='user[password]']"
        assert_select "input[type='password'][name='user[password_confirmation]']"
      end
    end
  end

  context "PUT update" do
    setup do
      organisation = create(:organisation)
      @invitee = User.invite!(attributes_for(:user, organisation:))
      @token = @invitee.raw_invitation_token
      @password = User.send(:random_password)
    end

    context "when invitation is accepted successfully" do
      should "set invitation accepted timestamp on invitee" do
        freeze_time do
          put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: @password } }

          assert_equal Time.current, @invitee.reload.invitation_accepted_at
        end
      end

      should "redirect to sign in page" do
        put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: @password } }

        assert_redirected_to new_user_session_path
      end

      should "not allow invitee role to be changed" do
        new_role = Roles::Superadmin.role_name

        put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: @password, role: new_role } }

        assert_equal @invitee.role, @invitee.reload.role
      end

      should "not allow invitee organisation to be changed" do
        new_organisation = create(:organisation)

        put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: @password, organisation_id: new_organisation } }

        assert_equal @invitee.organisation, @invitee.reload.organisation
      end

      should "not allow invitee require_2sv to be changed" do
        put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: @password, require_2sv: true } }

        assert_not @invitee.reload.require_2sv?
      end
    end

    context "when invitation token is invalid" do
      should "not set invitation accepted timestamp on invitee" do
        put :update, params: { user: { invitation_token: "invalid", password: @password, password_confirmation: @password } }

        assert @invitee.reload.invitation_accepted_at.nil?
      end

      should "re-render edit page" do
        put :update, params: { user: { invitation_token: "invalid", password: @password, password_confirmation: @password } }

        assert_template :edit
      end

      should "display error message" do
        put :update, params: { user: { invitation_token: "invalid", password: @password, password_confirmation: @password } }

        assert_select ".govuk-error-summary" do
          assert_select "li", text: "Invitation token is invalid"
        end
      end
    end

    context "when passwords is not strong enough" do
      should "not set invitation accepted timestamp on invitee" do
        put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: "does-not-match" } }

        assert @invitee.reload.invitation_accepted_at.nil?
      end

      should "re-render edit page" do
        put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: "does-not-match" } }

        assert_template :edit
      end

      should "display error message" do
        new_password = "zymophosphate"

        put :update, params: { user: { invitation_token: @token, password: new_password, password_confirmation: new_password } }

        assert_select ".govuk-error-summary" do
          assert_select "a", href: "user_password", text: /Password not strong enough/
        end
        assert_select ".govuk-form-group" do
          assert_select ".govuk-error-message", text: /Error: Password not strong enough/
          assert_select "input[name='user[password]'].govuk-input--error"
        end
      end
    end

    context "when passwords do not match" do
      should "not set invitation accepted timestamp on invitee" do
        put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: "does-not-match" } }

        assert @invitee.reload.invitation_accepted_at.nil?
      end

      should "re-render edit page" do
        put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: "does-not-match" } }

        assert_template :edit
      end

      should "display error message" do
        put :update, params: { user: { invitation_token: @token, password: @password, password_confirmation: "does-not-match" } }

        assert_select ".govuk-error-summary" do
          assert_select "a", href: "user_password_confirmation", text: "Password confirmation doesn't match Password"
        end
        assert_select ".govuk-form-group" do
          assert_select ".govuk-error-message", text: "Error: Password confirmation doesn't match Password"
          assert_select "input[name='user[password_confirmation]'].govuk-input--error"
        end
      end
    end
  end
end
