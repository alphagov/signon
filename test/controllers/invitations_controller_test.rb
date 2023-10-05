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
    end

    context "when inviter is signed in as a superadmin" do
      setup do
        sign_in create(:superadmin_user)
      end

      should "allow access" do
        get :new

        assert_template :new
      end
    end

    context "when inviter is signed in as a normal (non-admin) user" do
      setup do
        sign_in create(:user)
      end

      should "disallow access" do
        get :new

        assert_redirected_to root_path
      end
    end

    context "when inviter is signed in as an organisation admin" do
      setup do
        sign_in create(:organisation_admin_user)
      end

      should "disallow access" do
        get :new

        assert_redirected_to root_path
      end
    end

    context "when inviter is signed in as a super organisation admin" do
      setup do
        sign_in create(:super_organisation_admin_user)
      end

      should "disallow access" do
        get :new

        assert_redirected_to root_path
      end
    end

    context "when inviter is not signed in" do
      should "require inviter to be signed in" do
        get :new

        assert_redirected_to new_user_session_path
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

      should "save invitee with default supported permissions" do
        default_permission = create(:supported_permission, default: true)
        non_default_permission = create(:supported_permission, default: false)

        post :create, params: {
          user: { name: "invitee", email: "invitee@gov.uk", supported_permission_ids: [non_default_permission.to_param] },
        }

        invitee = User.last
        assert_same_elements [default_permission, non_default_permission], invitee.supported_permissions
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
          assert_select "select[name='user[supported_permission_ids][]']" do
            assert_select "option[value='#{other_permission.to_param}'][selected]"
          end
        end
      end

      should "record account invitation in event log when invitation sent" do
        EventLog.expects(:record_account_invitation).with(instance_of(User), @inviter)

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

        assert_redirected_to root_path
      end
    end

    context "when inviter is signed in as an organisation admin" do
      setup do
        sign_in create(:organisation_admin_user)
      end

      should "disallow access" do
        post :create, params: { user: { name: "org-admin-invitee", email: "org-admin-invitee@gov.uk" } }

        assert_redirected_to root_path
      end
    end

    context "when inviter is signed in as a super organisation admin" do
      setup do
        sign_in create(:super_organisation_admin_user)
      end

      should "disallow access" do
        post :create, params: { user: { name: "super-org-admin-invitee", email: "super-org-admin-invitee@gov.uk" } }

        assert_redirected_to root_path
      end
    end

    context "when inviter is not signed in" do
      should "require inviter to be signed in" do
        post :create

        assert_redirected_to new_user_session_path
      end
    end
  end

  context "POST resend" do
    setup do
      @user_to_resend_for = create(:user)
    end

    context "when inviter is signed in as a superadmin" do
      setup do
        sign_in create(:superadmin_user)
      end

      should "resend account signup email to invitee" do
        User.any_instance.expects(:invite!).once

        post :resend, params: { id: @user_to_resend_for }

        assert_redirected_to users_path
      end
    end

    context "when inviter is signed in as a normal (non-admin) user" do
      setup do
        sign_in create(:user)
      end

      should "disallow access" do
        post :resend, params: { id: @user_to_resend_for }

        assert_redirected_to root_path
      end
    end

    context "when inviter is signed in as an organisation admin" do
      setup do
        sign_in create(:organisation_admin_user)
      end

      should "disallow access" do
        post :resend, params: { id: @user_to_resend_for }

        assert_redirected_to root_path
      end
    end

    context "when inviter is signed in as a super organisation admin" do
      setup do
        sign_in create(:super_organisation_admin_user)
      end

      should "disallow access" do
        post :resend, params: { id: @user_to_resend_for }

        assert_redirected_to root_path
      end
    end

    context "when inviter is not signed in" do
      should "require inviter to be signed in" do
        user_to_resend_for = create(:user)
        post :resend, params: { id: user_to_resend_for }

        assert_redirected_to new_user_session_path
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

        assert_select ".govuk-error-summary__title", text: "There was a problem changing your password"
        assert_select ".govuk-error-summary__body", text: "Invitation token is invalid"
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

        assert_select ".govuk-error-summary__title", text: "There was a problem changing your password"
        assert_select ".govuk-error-summary__body", text: "Password confirmation doesn't match Password"
      end
    end
  end
end
