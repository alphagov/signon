require "test_helper"

class UsersControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  context "GET index" do
    context "signed in as Admin user" do
      setup do
        @user = create(:admin_user, email: "admin@gov.uk")
        sign_in @user
      end

      should "display 'Create user' button" do
        get :index

        assert_select "a", text: "Create user"
      end

      should "display 'Upload a batch of users' button" do
        get :index

        assert_select "a", text: "Upload a batch of users"
      end

      should "display 'Export N users as CSV' button" do
        get :index

        assert_select "a", text: "Export 1 user as CSV", href: users_path(format: "csv")
      end

      should "list users" do
        create(:user, email: "another_user@email.com")
        get :index
        assert_select "tr td:nth-child(2)", /another_user@email.com/
      end

      should "not list api users" do
        create(:api_user, email: "api_user@email.com")
        get :index
        assert_select "tr td:nth-child(2)", count: 0, text: /api_user@email.com/
      end

      should "not show superadmin users" do
        create(:superadmin_user, email: "superadmin@email.com")

        get :index

        assert_select "tbody tr", count: 1
        assert_select "tr td:nth-child(2)", /#{@user.email}/
      end

      should "show user roles" do
        create(:user, email: "user@email.com")
        create(:super_organisation_admin_user, email: "superorgadmin@email.com")
        create(:organisation_admin_user, email: "orgadmin@email.com")

        get :index

        assert_select "tr td:nth-child(3)", /Normal/
        assert_select "tr td:nth-child(3)", /Organisation admin/
        assert_select "tr td:nth-child(3)", /Super organisation admin/
        assert_select "tr td:nth-child(3)", /Admin/
      end

      context "filter" do
        should "filter by partially matching name" do
          create(:user, name: "does-match1")
          create(:user, name: "does-match2")
          create(:user, name: "does-not-match")

          get :index, params: { filter: "does-match" }

          assert_select "tr td:nth-child(1)", text: /does-match/, count: 2
        end

        should "filter by partially matching email" do
          create(:user, email: "does-match1@example.com")
          create(:user, email: "does-match2@example.com")
          create(:user, email: "does-not-match@example.com")

          get :index, params: { filter: "does-match" }

          assert_select "tr td:nth-child(2)", text: /does-match/, count: 2
        end

        should "filter by statuses" do
          create(:active_user, name: "active-user")
          create(:suspended_user, name: "suspended-user")
          create(:invited_user, name: "invited-user")
          create(:locked_user, name: "locked-user")

          get :index, params: { statuses: %w[locked suspended] }

          assert_select "tr td:nth-child(1)", text: /active-user/, count: 0
          assert_select "tr td:nth-child(1)", text: /suspended-user/
          assert_select "tr td:nth-child(1)", text: /invited-user/, count: 0
          assert_select "tr td:nth-child(1)", text: /locked-user/
        end

        should "filter by 2SV statuses" do
          create(:user, name: "not-set-up-user")
          create(:two_step_exempted_user, name: "exempted-user")
          create(:two_step_enabled_user, name: "enabled-user")

          get :index, params: { two_step_statuses: %w[not_setup_2sv exempt_from_2sv] }

          assert_select "tr td:nth-child(1)", text: /not-set-up-user/
          assert_select "tr td:nth-child(1)", text: /exempted-user/
          assert_select "tr td:nth-child(1)", text: /enabled-user/, count: 0
        end

        should "filter by roles" do
          create(:admin_user, name: "admin-user")
          create(:organisation_admin_user, name: "organisation-admin-user")
          create(:user, name: "normal-user")

          get :index, params: { roles: %w[admin normal] }

          assert_select "tr td:nth-child(1)", text: /admin-user/
          assert_select "tr td:nth-child(1)", text: /organisation-admin-user/, count: 0
          assert_select "tr td:nth-child(1)", text: /normal-user/
        end

        should "filter by permissions" do
          app1 = create(:application, name: "App 1")
          app2 = create(:application, name: "App 2")

          permission1 = create(:supported_permission, application: app1, name: "Permission 1")

          create(:user, name: "user1", supported_permissions: [app1.signin_permission, permission1])
          create(:user, name: "user2", supported_permissions: [])
          create(:user, name: "user3", supported_permissions: [app2.signin_permission, permission1])

          get :index, params: { permissions: [app1.signin_permission, app2.signin_permission] }

          assert_select "tr td:nth-child(1)", text: /user1/
          assert_select "tr td:nth-child(1)", text: /user2/, count: 0
          assert_select "tr td:nth-child(1)", text: /user3/
        end

        should "filter by organisations" do
          organisation1 = create(:organisation, name: "Organisation 1")
          organisation2 = create(:organisation, name: "Organisation 2")
          organisation3 = create(:organisation, name: "Organisation 3")

          create(:user, name: "user1-in-organisation1", organisation: organisation1)
          create(:user, name: "user2-in-organisation1", organisation: organisation1)
          create(:user, name: "user3-in-organisation2", organisation: organisation2)
          create(:user, name: "user4-in-organisation3", organisation: organisation3)

          get :index, params: { organisations: [organisation1, organisation3] }

          assert_select "tr td:nth-child(1)", text: /user1-in-organisation1/
          assert_select "tr td:nth-child(1)", text: /user2-in-organisation1/
          assert_select "tr td:nth-child(1)", text: /user3-in-organisation2/, count: 0
          assert_select "tr td:nth-child(1)", text: /user4-in-organisation3/
        end

        should "display link to clear all filters" do
          get :index

          assert_select "a", text: "Clear all filters", href: users_path
        end

        should "redirect legacy filters" do
          organisation1 = create(:organisation, name: "Organisation 1")

          get :index, params: { organisation: organisation1 }

          assert_redirected_to users_path(organisations: [organisation1])
        end
      end

      context "CSV export" do
        should "respond to CSV format" do
          get :index, params: { format: :csv }
          assert_response :success
          assert_equal "text/csv", @response.media_type
        end

        should "only include filtered users" do
          create(:user, name: "does-match")
          create(:user, name: "does-not-match")
          get :index, params: { filter: "does-match", format: :csv }
          number_of_users = CSV.parse(@response.body, headers: true).length
          assert_equal 1, number_of_users
        end

        should "include all users when no filter selected" do
          create(:user)
          get :index, params: { format: :csv }
          number_of_users = CSV.parse(@response.body, headers: true).length
          assert_equal User.count, number_of_users
        end
      end
    end

    context "signed in as Superadmin user" do
      setup do
        @user = create(:superadmin_user, email: "superadmin@gov.uk")
        sign_in @user
      end

      should "not list api users" do
        create(:api_user, email: "api_user@email.com")

        get :index

        assert_select "tr td:nth-child(2)", count: 0, text: /api_user@email.com/
      end
    end

    context "signed in as Organisation Admin user" do
      setup do
        @user = create(:organisation_admin_user)
        sign_in @user
      end

      should "not display 'Create user' button" do
        get :index

        assert_select "a", text: "Create user", count: 0
      end

      should "not display 'Upload a batch of users' button" do
        get :index

        assert_select "a", text: "Upload a batch of users", count: 0
      end

      should "not display organisations filter" do
        get :index

        assert_select "#organisations_filter", count: 0
      end
    end

    context "signed in as Normal user" do
      setup do
        @user = create(:normal_user)
        sign_in @user
      end

      should "disallow access" do
        get :index
        assert_not_authorised
      end
    end
  end

  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        @user = create(:admin_user, email: "admin@gov.uk")
        sign_in @user
      end

      context "for the currently logged in user" do
        should "redirect to the account page" do
          get :edit, params: { id: @user.id }
          assert_redirected_to account_path
        end
      end

      should "display the user's name and a link to change the name" do
        not_an_admin = create(:user, name: "user-name")
        get :edit, params: { id: not_an_admin.id }
        assert_select "*", text: /Name\s+user-name/
        assert_select "a", href: edit_user_name_path(not_an_admin), text: /Change\s+Name/
      end

      should "display the user's email and a link to change the email" do
        not_an_admin = create(:user, email: "user-name@gov.uk")
        get :edit, params: { id: not_an_admin.id }
        assert_select "*", text: /Email\s+user-name@gov.uk/
        assert_select "a", href: edit_user_email_path(not_an_admin), text: /Change\s+Email/
      end

      should "display the user's role but no link to change the role" do
        user = create(:user, role: Roles::Normal.role_name)
        get :edit, params: { id: user.id }
        assert_select "*", text: /Role\s+Normal/
        assert_select "a", href: edit_user_role_path(user), text: /Change\s+Role/, count: 0
      end

      should "display the user's organisation and a link to change the organisation" do
        user_in_org = create(:user_in_organisation)
        org_with_user = user_in_org.organisation

        get :edit, params: { id: user_in_org.id }

        assert_select "*", text: /Organisation\s+#{org_with_user.name}/
        assert_select "a", href: edit_user_organisation_path(user_in_org), text: /Change\s+Organisation/
      end

      should "display link to access log page for user" do
        user = create(:user)

        get :edit, params: { id: user }

        assert_select "a[href='#{event_logs_user_path(user)}']", text: "Account access log"
      end

      should "display link to resend invitation page for user who has been invited but has not accepted" do
        user = create(:invited_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_invitation_resend_path(user)}']", text: "Resend signup email"
      end

      should "not display link to resend invitation page for user who has accepted invitation" do
        user = create(:active_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_invitation_resend_path(user)}']", count: 0
      end

      should "display link to unlock user page" do
        user = create(:locked_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_unlocking_path(user)}']", text: "Unlock account"
      end

      should "not display link to unlock user page for user that has not been locked" do
        user = create(:active_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_unlocking_path(user)}']", count: 0
      end

      should "display suspend link for user that is not suspended" do
        user = create(:active_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_suspension_path(user)}']", text: "Suspend user"
      end

      should "display unsuspend link for user that is suspended" do
        user = create(:suspended_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_suspension_path(user)}']", text: "Unsuspend user"
      end

      should "display reset 2SV link for user that has 2SV setup" do
        user = create(:two_step_enabled_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_two_step_verification_reset_path(user)}']", text: "Reset 2-step verification"
      end

      should "not display reset 2SV link for user that does not have 2SV setup" do
        user = create(:active_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_two_step_verification_reset_path(user)}']", count: 0
      end

      should "not be able to edit superadmins" do
        superadmin = create(:superadmin_user)

        get :edit, params: { id: superadmin.id }

        assert_not_authorised
      end
    end

    context "signed in as Organisation Admin user" do
      setup do
        @organisation_admin = create(:organisation_admin_user)
        sign_in @organisation_admin
      end

      should "not display a link to change the user's role" do
        user = create(:user, organisation: @organisation_admin.organisation)

        get :edit, params: { id: user.id }

        assert_select "a", href: edit_user_role_path(user), text: /Change\s+Role/, count: 0
      end

      should "not display a link to change the user's organisation" do
        user = create(:user_in_organisation, organisation: @organisation_admin.organisation)

        get :edit, params: { id: user.id }

        assert_select "a", href: edit_user_organisation_path(user), text: /Change\s+Organisation/, count: 0
      end

      should "display link to resend invitation page for user who has been invited but has not accepted" do
        user = create(:invited_user, organisation: @organisation_admin.organisation)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_invitation_resend_path(user)}']"
      end

      should "display link to unlock user page" do
        user = create(:locked_user, organisation: @organisation_admin.organisation)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_unlocking_path(user)}']"
      end

      should "display suspend link for user that is not suspended" do
        user = create(:active_user, organisation: @organisation_admin.organisation)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_suspension_path(user)}']", text: "Suspend user"
      end

      should "display reset 2SV link for user that has 2SV setup" do
        user = create(:two_step_enabled_user, organisation: @organisation_admin.organisation)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_two_step_verification_reset_path(user)}']", text: "Reset 2-step verification"
      end
    end

    context "signed in as Super Organisation Admin user" do
      setup do
        @super_organisation_admin = create(:super_organisation_admin_user)
        sign_in @super_organisation_admin
      end

      should "not display a link to change the user's role" do
        user = create(:user, organisation: @super_organisation_admin.organisation)

        get :edit, params: { id: user.id }

        assert_select "a", href: edit_user_role_path(user), text: /Change\s+Role/, count: 0
      end

      should "not display a link to change the user's organisation" do
        user = create(:user_in_organisation, organisation: @super_organisation_admin.organisation)

        get :edit, params: { id: user.id }

        assert_select "a", href: edit_user_organisation_path(user), text: /Change\s+Organisation/, count: 0
      end

      should "display link to resend invitation page for user who has been invited but has not accepted" do
        user = create(:invited_user, organisation: @super_organisation_admin.organisation)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_invitation_resend_path(user)}']"
      end

      should "display link to unlock user page" do
        user = create(:locked_user, organisation: @super_organisation_admin.organisation)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_unlocking_path(user)}']"
      end

      should "display suspend link for user that is not suspended" do
        user = create(:active_user, organisation: @super_organisation_admin.organisation)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_suspension_path(user)}']", text: "Suspend user"
      end

      should "display reset 2SV link for user that has 2SV setup" do
        user = create(:two_step_enabled_user, organisation: @super_organisation_admin.organisation)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_two_step_verification_reset_path(user)}']", text: "Reset 2-step verification"
      end
    end

    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in @superadmin
      end

      should "display a link to change the user's role" do
        user = create(:user, role: Roles::Normal.role_name)
        get :edit, params: { id: user.id }
        assert_select "a", href: edit_user_role_path(user), text: /Change\s+Role/
      end

      should "display link to resend invitation page for user who has been invited but has not accepted" do
        user = create(:invited_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_invitation_resend_path(user)}']"
      end

      should "display link to unlock user page" do
        user = create(:locked_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_unlocking_path(user)}']"
      end

      should "display suspend link for user that is not suspended" do
        user = create(:active_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_suspension_path(user)}']", text: "Suspend user"
      end

      should "display reset 2SV link for user that has 2SV setup" do
        user = create(:two_step_enabled_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_two_step_verification_reset_path(user)}']", text: "Reset 2-step verification"
      end
    end

    context "signed in as Normal user" do
      setup do
        @user = create(:user, email: "normal@gov.uk")
        sign_in @user
      end

      context "when current user tries to edit their own user" do
        should "redirect to the account page" do
          get :edit, params: { id: @user }

          assert_redirected_to account_path
        end
      end

      context "when current user tries to edit another user" do
        should "redirect to the dashboard and explain user does not have permission" do
          another_user = create(:user)

          get :edit, params: { id: another_user }

          assert_not_authorised
        end
      end
    end
  end

  context "GET manage_permissions" do
    context "signed in as Admin user" do
      setup do
        @user = create(:admin_user, email: "admin@gov.uk")
        sign_in @user
      end

      context "for the currently logged in user" do
        should "redirect to the account page" do
          get :manage_permissions, params: { id: @user.id }
          assert_redirected_to account_path
        end
      end

      should "not be able to manage permissions for superadmins" do
        superadmin = create(:superadmin_user)

        get :manage_permissions, params: { id: superadmin.id }

        assert_not_authorised
      end

      should "can give permissions to all applications" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

        @user.grant_application_signin_permission(delegatable_app)
        @user.grant_application_signin_permission(non_delegatable_app)

        user = create(:user_in_organisation)

        get :manage_permissions, params: { id: user.id }

        assert_select ".container" do
          # can give permissions to a delegatable app
          assert_select "td", count: 1, text: delegatable_app.name
          # can give permissions to a non delegatable app
          assert_select "td", count: 1, text: non_delegatable_app.name
          # can give permissions to a delegatable app the admin doesn't have access to
          assert_select "td", count: 1, text: delegatable_no_access_to_app.name
          # can give permissions to a non-delegatable app the admin doesn't have access to
          assert_select "td", count: 1, text: non_delegatable_no_access_to_app.name
        end
      end
    end

    context "signed in as Organisation Admin user" do
      setup do
        @organisation_admin = create(:organisation_admin_user)
        sign_in @organisation_admin
      end

      should "be able to give permissions only to applications they themselves have access to and that also have delegatable signin permissions" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

        @organisation_admin.grant_application_signin_permission(delegatable_app)
        @organisation_admin.grant_application_signin_permission(non_delegatable_app)

        user = create(:user_in_organisation, organisation: @organisation_admin.organisation)

        get :manage_permissions, params: { id: user.id }

        assert_select "#editable-permissions" do
          # can give access to a delegatable app they have access to
          assert_select "td", count: 1, text: delegatable_app.name
          # can not give access to a non-delegatable app they have access to
          assert_select "td", count: 0, text: non_delegatable_app.name
          # can not give access to a delegatable app they do not have access to
          assert_select "td", count: 0, text: delegatable_no_access_to_app.name
          # can not give access to a non delegatable app they do not have access to
          assert_select "td", count: 0, text: non_delegatable_no_access_to_app.name
        end
      end

      should "be able to see all permissions to applications for a user" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME, "Editor"])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME, "GDS Admin"])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME, "GDS Editor"])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME, "Import CSVs"])

        @organisation_admin.grant_application_signin_permission(delegatable_app)
        @organisation_admin.grant_application_signin_permission(non_delegatable_app)

        user = create(
          :user_in_organisation,
          organisation: @organisation_admin.organisation,
          with_permissions: { delegatable_app => %w[Editor],
                              non_delegatable_app => [SupportedPermission::SIGNIN_NAME, "GDS Admin"],
                              delegatable_no_access_to_app => [SupportedPermission::SIGNIN_NAME, "GDS Editor"],
                              non_delegatable_no_access_to_app => [SupportedPermission::SIGNIN_NAME, "Import CSVs"] },
        )

        get :manage_permissions, params: { id: user.id }

        assert_select "h2", "All Permissions for this user"
        assert_select "#all-permissions" do
          # can see permissions for a delegatable app the user has access to
          assert_select "td", count: 1, text: delegatable_app.name
          # can see permissions to a non-delegatable app the user has access to
          assert_select "td", count: 1, text: non_delegatable_app.name
          # can see permissions to a delegatable app the user has access to
          assert_select "td", count: 1, text: delegatable_no_access_to_app.name
          # can see permissions to a non delegatable app the user has access to
          assert_select "td", count: 1, text: non_delegatable_no_access_to_app.name
          # can see that user has signin permission for three of the four applications in "Has access?" column
          assert_select "td", count: 3, text: "Yes"
          assert_select "td", count: 1, text: "No"
          # can see role
          assert_select "td", count: 1, text: "Editor"
          assert_select "td", count: 1, text: "GDS Admin"
          assert_select "td", count: 1, text: "GDS Editor"
          assert_select "td", count: 1, text: "Import CSVs"
        end
      end
    end

    context "signed in as Super Organisation Admin user" do
      setup do
        @super_organisation_admin = create(:super_organisation_admin_user)
        sign_in @super_organisation_admin
      end

      should "be able to give permissions only to applications they themselves have access to and that also have delegatable signin permissions" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

        @super_organisation_admin.grant_application_signin_permission(delegatable_app)
        @super_organisation_admin.grant_application_signin_permission(non_delegatable_app)

        user = create(:user_in_organisation, organisation: @super_organisation_admin.organisation)

        get :manage_permissions, params: { id: user.id }

        assert_select "#editable-permissions" do
          # can give access to a delegatable app they have access to
          assert_select "td", count: 1, text: delegatable_app.name
          # can not give access to a non-delegatable app they have access to
          assert_select "td", count: 0, text: non_delegatable_app.name
          # can not give access to a delegatable app they do not have access to
          assert_select "td", count: 0, text: delegatable_no_access_to_app.name
          # can not give access to a non delegatable app they do not have access to
          assert_select "td", count: 0, text: non_delegatable_no_access_to_app.name
        end
      end

      should "be able to see all permissions to applications for a user" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME, "Editor"])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME, "GDS Admin"])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME, "GDS Editor"])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME, "Import CSVs"])

        @super_organisation_admin.grant_application_signin_permission(delegatable_app)
        @super_organisation_admin.grant_application_signin_permission(non_delegatable_app)

        user = create(
          :user_in_organisation,
          organisation: @super_organisation_admin.organisation,
          with_permissions: { delegatable_app => %w[Editor],
                              non_delegatable_app => [SupportedPermission::SIGNIN_NAME, "GDS Admin"],
                              delegatable_no_access_to_app => [SupportedPermission::SIGNIN_NAME, "GDS Editor"],
                              non_delegatable_no_access_to_app => [SupportedPermission::SIGNIN_NAME, "Import CSVs"] },
        )

        get :manage_permissions, params: { id: user.id }

        assert_select "h2", "All Permissions for this user"
        assert_select "#all-permissions" do
          # can see permissions for a delegatable app the user has access to
          assert_select "td", count: 1, text: delegatable_app.name
          # can see permissions to a non-delegatable app the user has access to
          assert_select "td", count: 1, text: non_delegatable_app.name
          # can see permissions to a delegatable app the user has access to
          assert_select "td", count: 1, text: delegatable_no_access_to_app.name
          # can see permissions to a non delegatable app the user has access to
          assert_select "td", count: 1, text: non_delegatable_no_access_to_app.name
          # can see that user has signin permission for three of the four applications in "Has access?" column
          assert_select "td", count: 3, text: "Yes"
          assert_select "td", count: 1, text: "No"
          # can see role
          assert_select "td", count: 1, text: "Editor"
          assert_select "td", count: 1, text: "GDS Admin"
          assert_select "td", count: 1, text: "GDS Editor"
          assert_select "td", count: 1, text: "Import CSVs"
        end
      end

      should "not be able to see permissions to retired applications for a user" do
        retired_app = create(:application, retired: true)

        user = create(:user_in_organisation, organisation: @super_organisation_admin.organisation)
        create(:user_application_permission, application: retired_app, user:)

        get :manage_permissions, params: { id: user.id }

        assert_select "h2", "All Permissions for this user"
        assert_select "#all-permissions" do
          assert_select "td", text: retired_app.name, count: 0
        end
      end

      should "not be able to see permissions to API-only applications for a user" do
        api_only_app = create(:application, api_only: true)

        user = create(:user_in_organisation, organisation: @super_organisation_admin.organisation)
        create(:user_application_permission, application: api_only_app, user:)

        get :manage_permissions, params: { id: user.id }

        assert_select "h2", "All Permissions for this user"
        assert_select "#all-permissions" do
          assert_select "td", text: api_only_app.name, count: 0
        end
      end
    end

    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in @superadmin
      end

      should "not be able to see all permissions to applications for a user" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME, "Editor"])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME, "GDS Admin"])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME, "GDS Editor"])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME, "Import CSVs"])

        @superadmin.grant_application_signin_permission(delegatable_app)
        @superadmin.grant_application_signin_permission(non_delegatable_app)

        user = create(
          :user_in_organisation,
          organisation: @superadmin.organisation,
          with_permissions: { delegatable_app => %w[Editor],
                              non_delegatable_app => [SupportedPermission::SIGNIN_NAME, "GDS Admin"],
                              delegatable_no_access_to_app => [SupportedPermission::SIGNIN_NAME, "GDS Editor"],
                              non_delegatable_no_access_to_app => [SupportedPermission::SIGNIN_NAME, "Import CSVs"] },
        )

        get :manage_permissions, params: { id: user.id }

        assert_select "h2", count: 0, text: "All Permissions for this user"
        assert_select "#all-permissions", count: 0
      end
    end

    context "signed in as Normal user" do
      setup do
        @user = create(:user, email: "normal@gov.uk")
        sign_in @user
      end

      context "when current user tries to manage their own permissions" do
        should "redirect to the account page" do
          get :manage_permissions, params: { id: @user }

          assert_redirected_to account_path
        end
      end

      context "when current user tries to manage another user's permissions" do
        should "redirect to the dashboard and explain user does not have permission" do
          another_user = create(:user)

          get :manage_permissions, params: { id: another_user }

          assert_not_authorised
        end
      end
    end
  end

  context "PUT update" do
    context "signed in as Admin user" do
      setup do
        @user = create(:admin_user, email: "admin@gov.uk")
        sign_in @user
      end

      should "not be able to update superadmins" do
        superadmin = create(:superadmin_user)

        put :edit, params: { id: superadmin.id, user: {} }

        assert_not_authorised
      end

      should "push changes out to apps" do
        another_user = create(:user)
        PermissionUpdater.expects(:perform_on).with(another_user).once

        put :update, params: { id: another_user.id, user: {} }
      end

      context "update application access" do
        setup do
          sign_in create(:admin_user)
          @application = create(:application)
          @another_user = create(:user)
        end

        should "remove all applications access for a user" do
          @another_user.grant_application_signin_permission(@application)

          put :update, params: { id: @another_user.id, user: {} }

          assert_empty @another_user.reload.application_permissions
        end

        should "add application access for a user" do
          put(
            :update,
            params: {
              id: @another_user.id,
              user: {
                supported_permission_ids: [
                  @application.supported_permissions.first.id,
                ],
              },
            },
          )

          assert_equal 1, @another_user.reload.application_permissions.count
        end
      end
    end

    context "signed in as Organisation Admin user" do
      setup do
        @organisation_admin = create(:organisation_admin_user)
        sign_in(@organisation_admin)
      end

      should "redisplay the form if save fails" do
        organisation = @organisation_admin.organisation
        organisation_admin_for_same_organisation = create(:organisation_admin_user, organisation:)
        UserUpdate.stubs(:new).returns(stub("UserUpdate", call: false))

        put :update, params: { id: organisation_admin_for_same_organisation.id, user: {} }

        assert_select "form#edit_user_#{organisation_admin_for_same_organisation.id}"
      end
    end

    context "signed in as Super Organisation Admin user" do
      setup do
        @super_organisation_admin = create(:super_organisation_admin_user)
        sign_in(@super_organisation_admin)
      end

      should "redisplay the form if save fails" do
        organisation = @super_organisation_admin.organisation
        super_organisation_admin_for_same_organisation = create(:super_organisation_admin_user, organisation:)
        UserUpdate.stubs(:new).returns(stub("UserUpdate", call: false))

        put :update, params: { id: super_organisation_admin_for_same_organisation.id, user: {} }

        assert_select "form#edit_user_#{super_organisation_admin_for_same_organisation.id}"
      end
    end
  end
end
