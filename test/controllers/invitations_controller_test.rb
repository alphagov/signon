require "test_helper"

class InvitationsControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  context "GET new" do
    context "when not signed in" do
      should "require user to be signed in" do
        get :new

        assert_redirected_to new_user_session_path
      end
    end

    context "when signed in" do
      setup do
        @user = create(:superadmin_user)
        sign_in @user
      end

      should "disallow access to non-admins" do
        @user.update_column(:role, "normal")
        get :new
        assert_redirected_to root_path
      end

      should "disallow access to organisation admins" do
        @user.update!(role: Roles::OrganisationAdmin.role_name, organisation_id: create(:organisation).id)
        get :new
        assert_redirected_to root_path
      end

      should "disallow access to super organisation admins" do
        @user.update!(role: Roles::SuperOrganisationAdmin.role_name, organisation_id: create(:organisation).id)
        get :new
        assert_redirected_to root_path
      end
    end
  end

  context "POST create" do
    context "when not signed in" do
      should "require user to be signed in" do
        post :create

        assert_redirected_to new_user_session_path
      end
    end

    context "when signed in" do
      setup do
        @user = create(:superadmin_user)
        sign_in @user
      end

      should "disallow access to non-admins" do
        @user.update_column(:role, "normal")
        post :create, params: { user: { name: "Testing Non-admins", email: "testing_non_admins@example.com" } }
        assert_redirected_to root_path
      end

      should "not allow creation of api users" do
        post :create, params: { user: { name: "Testing APIs", email: "api@example.com", api_user: true } }

        assert_empty User.where(api_user: true)
      end

      should "redirect to users page and display flash alert when inviting an existing user" do
        user = create(:user)

        post :create, params: { user: { name: user.name, email: user.email } }

        assert_redirected_to users_path
        assert_equal "User already invited. If you want to, you can click 'Resend signup email'.", flash[:alert]
      end

      should "disallow access to organisation admins" do
        @user.update!(role: Roles::OrganisationAdmin.role_name, organisation_id: create(:organisation).id)
        post :create, params: { user: { name: "Testing Org Admins", email: "testing_org_admins@example.com" } }
        assert_redirected_to root_path
      end

      should "disallow access to super organisation admins" do
        @user.update!(role: Roles::SuperOrganisationAdmin.role_name, organisation_id: create(:organisation).id)
        post :create, params: { user: { name: "Testing Org Admins", email: "testing_org_admins@example.com" } }
        assert_redirected_to root_path
      end

      should "save user and render 2SV form when user assigned to organisation that does not require 2SV" do
        organisation = create(:organisation, require_2sv: false)

        post :create, params: { user: { name: "User Name", email: "person@gov.uk", organisation_id: organisation.id } }

        assert_redirected_to require_2sv_user_path(User.last)
        assert_equal "User Name", User.last.name
      end

      should "save user and not render 2SV form when user assigned to organisation that requires 2SV" do
        organisation = create(:organisation, require_2sv: true)

        post :create, params: { user: { name: "User Name", email: "person@gov.uk", organisation_id: organisation.id } }

        assert_redirected_to users_path
        assert_equal "User Name", User.last.name
      end

      should "not render 2SV form and saves user when user is a superadmin" do
        organisation = create(:organisation, require_2sv: false)

        post :create, params: { user: { name: "User Name", email: "person@gov.uk", organisation_id: organisation.id, role: Roles::Superadmin.role_name } }

        assert_redirected_to users_path
        assert_equal "User Name", User.last.name
        assert User.last.require_2sv
      end

      should "not render 2SV form and saves user when user is an admin" do
        organisation = create(:organisation, require_2sv: false)

        post :create, params: { user: { name: "User Name", email: "person@gov.uk", organisation_id: organisation.id, role: Roles::Admin.role_name } }

        assert_redirected_to users_path
        assert_equal "User Name", User.last.name
        assert User.last.require_2sv
      end

      should "not render 2SV form and saves user when user is an organisation admin" do
        organisation = create(:organisation, require_2sv: false)

        post :create, params: { user: { name: "User Name", email: "person@gov.uk", organisation_id: organisation.id, role: Roles::OrganisationAdmin.role_name } }

        assert_redirected_to users_path
        assert_equal "User Name", User.last.name
        assert User.last.require_2sv
      end

      should "not render 2SV form and saves user when user is an super organisation admin" do
        organisation = create(:organisation, require_2sv: false)

        post :create, params: { user: { name: "User Name", email: "person@gov.uk", organisation_id: organisation.id, role: Roles::SuperOrganisationAdmin.role_name } }

        assert_redirected_to users_path
        assert_equal "User Name", User.last.name
        assert User.last.require_2sv
      end

      should "re-render form and not save user if there are validation errors" do
        post :create, params: { user: { name: "User Name", email: "" } }

        assert_template :new
        assert_not User.exists?(name: "User Name")
      end
    end
  end

  context "POST resend" do
    context "when not signed in" do
      should "require user to be signed in" do
        user_to_resend_for = create(:user)
        post :resend, params: { id: user_to_resend_for.id }

        assert_redirected_to new_user_session_path
      end
    end

    context "when signed in" do
      setup do
        @user = create(:superadmin_user)
        sign_in @user
      end

      should "disallow access to non-admins" do
        @user.update_column(:role, "normal")
        user_to_resend_for = create(:user)
        post :resend, params: { id: user_to_resend_for.id }
        assert_redirected_to root_path
      end

      should "disallow access to organisation admins" do
        @user.update!(role: Roles::OrganisationAdmin.role_name, organisation_id: create(:organisation).id)
        user_to_resend_for = create(:user)
        post :resend, params: { id: user_to_resend_for.id }
        assert_redirected_to root_path
      end

      should "disallow access to super organisation admins" do
        @user.update!(role: Roles::SuperOrganisationAdmin.role_name, organisation_id: create(:organisation).id)
        user_to_resend_for = create(:user)
        post :resend, params: { id: user_to_resend_for.id }
        assert_redirected_to root_path
      end

      should "resend account signup email to user" do
        admin = create(:admin_user)
        user_to_resend_for = create(:user)
        User.any_instance.expects(:invite!).once
        sign_in admin

        post :resend, params: { id: user_to_resend_for.id }

        assert_redirected_to users_path
      end
    end
  end
end
