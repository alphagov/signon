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
        assert_redirected_to root_path
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
        assert_select "*", text: /Name: user-name/
        assert_select "a", href: edit_user_name_path(not_an_admin), text: "Change name"
      end

      should "show the form with an email field" do
        not_an_admin = create(:user)
        get :edit, params: { id: not_an_admin.id }
        assert_select "form[action='#{user_path(not_an_admin)}']" do
          assert_select "input[name='user[email]'][value='#{not_an_admin.email}']"
        end
      end

      should "show the pending email if applicable" do
        another_user = create(:user_with_pending_email_change)
        get :edit, params: { id: another_user.id }
        assert_select "input[name='user[unconfirmed_email]'][value='#{another_user.unconfirmed_email}']"
      end

      should "show the organisation to which the user belongs" do
        user_in_org = create(:user_in_organisation)
        org_with_user = user_in_org.organisation
        other_organisation = create(:organisation, abbreviation: "ABBR")

        get :edit, params: { id: user_in_org.id }

        assert_select "select[name='user[organisation_id]']" do
          assert_select "option", count: 3
          assert_select "option[selected=selected]", count: 1
          assert_select %(option[value="#{org_with_user.id}"][selected=selected]), text: org_with_user.name_with_abbreviation
          assert_select %(option[value="#{other_organisation.id}"]), text: other_organisation.name_with_abbreviation
        end
      end

      should "not be able to edit superadmins" do
        superadmin = create(:superadmin_user)

        get :edit, params: { id: superadmin.id }

        assert_redirected_to root_path
        assert_match(/You do not have permission to perform this action./, flash[:alert])
      end

      should "can give permissions to all applications" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

        @user.grant_application_signin_permission(delegatable_app)
        @user.grant_application_signin_permission(non_delegatable_app)

        user = create(:user_in_organisation)

        get :edit, params: { id: user.id }

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

      should "not be able to assign organisations" do
        create(:organisation)

        user = create(:user_in_organisation, organisation: @organisation_admin.organisation)

        get :edit, params: { id: user.id }

        assert_select "select[name='user[organisation_id]']", count: 0
      end

      should "be able to give permissions only to applications they themselves have access to and that also have delegatable signin permissions" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

        @organisation_admin.grant_application_signin_permission(delegatable_app)
        @organisation_admin.grant_application_signin_permission(non_delegatable_app)

        user = create(:user_in_organisation, organisation: @organisation_admin.organisation)

        get :edit, params: { id: user.id }

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

        get :edit, params: { id: user.id }

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

      should "not be able to assign organisations" do
        outside_organisation = create(:organisation)

        user = create(:user_in_organisation, organisation: @super_organisation_admin.organisation)

        get :edit, params: { id: user.id }

        assert_select "select[name='user[organisation_id]']", count: 0
        assert_select "td", count: 0, text: outside_organisation.id
      end

      should "be able to give permissions only to applications they themselves have access to and that also have delegatable signin permissions" do
        delegatable_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        delegatable_no_access_to_app = create(:application, with_delegatable_supported_permissions: [SupportedPermission::SIGNIN_NAME])
        non_delegatable_no_access_to_app = create(:application, with_supported_permissions: [SupportedPermission::SIGNIN_NAME])

        @super_organisation_admin.grant_application_signin_permission(delegatable_app)
        @super_organisation_admin.grant_application_signin_permission(non_delegatable_app)

        user = create(:user_in_organisation, organisation: @super_organisation_admin.organisation)

        get :edit, params: { id: user.id }

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

        get :edit, params: { id: user.id }

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

        get :edit, params: { id: user.id }

        assert_select "h2", "All Permissions for this user"
        assert_select "#all-permissions" do
          assert_select "td", text: retired_app.name, count: 0
        end
      end

      should "not be able to see permissions to API-only applications for a user" do
        api_only_app = create(:application, api_only: true)

        user = create(:user_in_organisation, organisation: @super_organisation_admin.organisation)
        create(:user_application_permission, application: api_only_app, user:)

        get :edit, params: { id: user.id }

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

        get :edit, params: { id: user.id }

        assert_select "h2", count: 0, text: "All Permissions for this user"
        assert_select "#all-permissions", count: 0
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

          assert_redirected_to root_path
          assert_equal "You do not have permission to perform this action.", flash[:alert]
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

        put :edit, params: { id: superadmin.id, user: { email: "normal_user@example.com" } }

        assert_redirected_to root_path
        assert_match(/You do not have permission to perform this action./, flash[:alert])
      end

      should "update the user's organisation" do
        user = create(:user_in_organisation)

        assert_not_nil user.organisation
        put :update, params: { id: user.id, user: { organisation_id: nil } }
        assert_nil user.reload.organisation
      end

      should "not let you set the role" do
        not_an_admin = create(:user)
        put :update, params: { id: not_an_admin.id, user: { role: Roles::Admin.role_name } }
        assert_equal "normal", not_an_admin.reload.role
      end

      context "changing an email" do
        should "not re-confirm email" do
          normal_user = create(:user, email: "old@email.com")
          put :update, params: { id: normal_user.id, user: { email: "new@email.com" } }

          assert_nil normal_user.reload.unconfirmed_email
          assert_equal "new@email.com", normal_user.email
        end

        should "log an event" do
          normal_user = create(:user, email: "old@email.com")
          put :update, params: { id: normal_user.id, user: { email: "new@email.com" } }

          assert_equal 1, EventLog.where(event_id: EventLog::EMAIL_CHANGED.id, uid: normal_user.uid, initiator_id: @user.id).count
        end

        should "send email change notifications to old and new email address" do
          perform_enqueued_jobs do
            normal_user = create(:user, email: "old@email.com")
            put :update, params: { id: normal_user.id, user: { email: "new@email.com" } }

            email_change_notifications = ActionMailer::Base.deliveries[-2..]
            assert_equal email_change_notifications.map(&:subject).uniq.count, 1
            assert_match(/Your .* Signon development email address has been updated/, email_change_notifications.map(&:subject).first)
            assert_equal(%w[old@email.com new@email.com], email_change_notifications.map { |mail| mail.to.first })
          end
        end

        context "an invited-but-not-yet-accepted user" do
          should "change the email, and send an invitation email" do
            perform_enqueued_jobs do
              another_user = User.invite!(name: "Ali", email: "old@email.com")
              put :update, params: { id: another_user.id, user: { email: "new@email.com" } }

              another_user.reload
              assert_equal "new@email.com", another_user.reload.email
              invitation_email = ActionMailer::Base.deliveries[-3]
              assert_equal "Please confirm your account", invitation_email.subject
              assert_equal "new@email.com", invitation_email.to.first
            end
          end
        end
      end

      should "push changes out to apps" do
        another_user = create(:user, name: "Old Name")
        PermissionUpdater.expects(:perform_on).with(another_user).once

        put :update, params: { id: another_user.id, user: { name: "New Name" } }
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

    context "signed in as a Superadmin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in @superadmin
      end

      should "update the user's role" do
        not_an_admin = create(:user)
        put :update, params: { id: not_an_admin.id, user: { role: Roles::Admin.role_name } }
        assert_equal Roles::Admin.role_name, not_an_admin.reload.role
      end

      context "changing a role" do
        should "log an event" do
          another_user = create(:admin_user)
          put :update, params: { id: another_user.id, user: { role: "normal" } }

          assert_equal 1, EventLog.where(event_id: EventLog::ROLE_CHANGED.id, uid: another_user.uid, initiator_id: @superadmin.id).count
        end
      end
    end

    context "signed in as Organisation Admin user" do
      setup do
        @organisation_admin = create(:organisation_admin_user)
        sign_in(@organisation_admin)
      end

      should "not be able to assign organisation ids" do
        sub_organisation = create(:organisation, parent: @organisation_admin.organisation)

        user = create(:user_in_organisation, organisation: sub_organisation)
        assert_not_nil user.organisation

        put :update, params: { id: user.id, user: { organisation_id: @organisation_admin.organisation.id } }

        assert_redirected_to root_path
        assert_match(/You do not have permission to perform this action./, flash[:alert])
      end

      should "redisplay the form if save fails" do
        organisation = @organisation_admin.organisation
        organisation_admin_for_same_organisation = create(:organisation_admin_user, organisation:)

        put :update, params: { id: organisation_admin_for_same_organisation.id, user: { email: "" } }

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

        put :update, params: { id: super_organisation_admin_for_same_organisation.id, user: { email: "" } }

        assert_select "form#edit_user_#{super_organisation_admin_for_same_organisation.id}"
      end
    end
  end

  context "PUT resend_email_change" do
    context "signed in as Admin user" do
      setup do
        @user = create(:admin_user, email: "admin@gov.uk")
        sign_in @user
      end

      should "send an email change confirmation email" do
        perform_enqueued_jobs do
          another_user = create(:user_with_pending_email_change)
          put :resend_email_change, params: { id: another_user.id }

          assert_equal "Confirm your email change", ActionMailer::Base.deliveries.last.subject
        end
      end

      should "use a new token if it's expired" do
        another_user = create(
          :user_with_pending_email_change,
          confirmation_token: "old token",
          confirmation_sent_at: 15.days.ago,
        )
        put :resend_email_change, params: { id: another_user.id }

        assert_not_equal "old token", another_user.reload.confirmation_token
      end
    end
  end

  context "DELETE cancel_email_change" do
    context "signed in as Admin user" do
      setup do
        @user = create(:admin_user, email: "admin@gov.uk")
        sign_in @user

        @another_user = create(:user_with_pending_email_change)
        request.env["HTTP_REFERER"] = edit_user_path(@another_user)
      end

      should "clear the unconfirmed_email and the confirmation_token" do
        delete :cancel_email_change, params: { id: @another_user.id }

        @another_user.reload
        assert_nil @another_user.unconfirmed_email
        assert_nil @another_user.confirmation_token
      end

      should "redirect to the edit user admin page" do
        delete :cancel_email_change, params: { id: @another_user.id }
        assert_redirected_to edit_user_path(@another_user)
      end
    end
  end
end
