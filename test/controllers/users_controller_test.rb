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
    should "display link to manage applications" do
      user = create(:user)

      current_user = create(:user)
      sign_in current_user

      stub_policy_for_navigation_links current_user
      stub_policy current_user, user, edit?: true

      get :edit, params: { id: user }

      assert_select "a[href='#{user_applications_path(user)}']"
    end

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
        user = create(:normal_user)
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

        assert_select "a[href='#{event_logs_user_path(user)}']", text: "View account access log"
      end

      should "display link to resend invitation page for user who has been invited but has not accepted" do
        user = create(:invited_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_invitation_resend_path(user)}']", text: "Resend signup email"
      end

      should "display link to unlock user page" do
        user = create(:locked_user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_unlocking_path(user)}']", text: "Unlock account"
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

      should "display mandate 2SV link for user for whom 2SV is not required" do
        user = create(:user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_user_two_step_verification_mandation_path(user)}']", text: "Turn on 2-step verification for this user"
      end

      should "not be able to edit superadmins" do
        superadmin = create(:superadmin_user)

        get :edit, params: { id: superadmin.id }

        assert_not_authorised
      end
    end

    context "signed in as GDS Admin user" do
      setup do
        @user = create(:admin_user, :in_gds_organisation, email: "admin@gov.uk")
        sign_in @user
      end

      should "display 2SV exemption link for user" do
        user = create(:user)

        get :edit, params: { id: user }

        assert_select "a[href='#{edit_two_step_verification_exemption_path(user)}']", text: "Exempt user from 2-step verification"
      end
    end

    context "signed in as Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in @superadmin
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

        put :update, params: { id: another_user.id, user: { require_2sv: true } }
      end
    end
  end

private

  def stub_policy_for_navigation_links(current_user)
    stub_policy(current_user, User, index?: true)
  end
end
