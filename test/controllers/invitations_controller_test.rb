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
        post :create, params: { user: { name: "invitee", email: "invitee@gov.uk", organisation_id: @organisation } }

        assert_equal "invitee", User.last.name
      end

      context "and invitee will be assigned to organisation not requiring 2SV" do
        setup do
          @organisation = create(:organisation, require_2sv: false)
        end

        should "render 2SV form allowing inviter to choose whether to require 2SV" do
          post :create, params: { user: { name: "invitee", email: "invitee@gov.uk", organisation_id: @organisation } }

          assert_redirected_to require_2sv_user_path(User.last)
        end

        should "not render 2SV form for superadmin invitee, because superadmins must use 2SV" do
          post :create, params: { user: { name: "superadmin-invitee", email: "superadmin-invitee@gov.uk", organisation_id: @organisation, role: Roles::Superadmin.role_name } }

          assert_redirected_to users_path
        end

        should "not render 2SV for admin invitee, because admins must use 2SV" do
          post :create, params: { user: { name: "admin-invitee", email: "admin-invitee@gov.uk", organisation_id: @organisation, role: Roles::Admin.role_name } }

          assert_redirected_to users_path
        end

        should "not render 2SV for organisation admin invitee, because organisation admins must use 2SV" do
          post :create, params: { user: { name: "org-admin-invitee", email: "org-admin-invitee@gov.uk", organisation_id: @organisation, role: Roles::OrganisationAdmin.role_name } }

          assert_redirected_to users_path
        end

        should "not render 2SV form for super organisation admin invitee, because super organisation admins must use 2SV" do
          post :create, params: { user: { name: "super-org-admin-invitee", email: "super-org-admin-invitee@gov.uk", organisation_id: @organisation, role: Roles::SuperOrganisationAdmin.role_name } }

          assert_redirected_to users_path
        end
      end

      context "and invitee will be assigned to organisation requiring 2SV" do
        setup do
          @organisation = create(:organisation, require_2sv: true)
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
end
