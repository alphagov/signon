require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  def change_user_password(user_factory, new_password)
    original_password = "I am a very original password. Refrigerator weevil."
    user = create(user_factory, password: original_password)
    original_password_hash = user.encrypted_password
    sign_in user

    post :update_passphrase, id: user.id, user: {
      current_password: original_password,
      password: new_password,
      password_confirmation: new_password
    }

    [user, original_password_hash]
  end

  context "PUT update_passphrase" do
    should "changing passwords to something strong should succeed" do
      user, orig_password = change_user_password(:user, 'destabilizers842}orthophosphate')

      assert_equal "302", response.code
      assert_equal root_url, response.location

      user.reload
      assert_not_equal orig_password, user.encrypted_password
    end

    should "changing password to something too short should fail" do
      user, orig_password = change_user_password(:user, 'short')

      assert_equal "200", response.code
      assert_match "too short", response.body

      user.reload
      assert_equal orig_password, user.encrypted_password
    end

    should "changing password to something too weak should fail" do
      user, orig_password = change_user_password(:user, 'zymophosphate')

      assert_equal "200", response.code
      assert_match "not strong enough", response.body

      user.reload
      assert_equal orig_password, user.encrypted_password
    end
  end

  context "GET edit_email_or_passphrase" do
    context "changing an email" do
      setup do
        @user = create(:user_with_pending_email_change)
        sign_in @user
      end

      should "show the unconfirmed_email" do
        get :edit_email_or_passphrase, id: @user.id

        assert_select "input#user_unconfirmed_email[value=?]", @user.unconfirmed_email
      end
    end
  end

  context "PUT update_email" do
    setup do
      @user = create(:user, email: "old@email.com")
      sign_in @user
    end

    context "changing an email" do
      should "stage the change, send a confirmation email to the new address and email change notification to the old address" do
        perform_enqueued_jobs do
          put :update_email, id: @user.id, user: { email: "new@email.com" }

          @user.reload

          assert_equal "new@email.com", @user.unconfirmed_email
          assert_equal "old@email.com", @user.email

          confirmation_email = ActionMailer::Base.deliveries[-2]
          assert_equal "Confirm your email change", confirmation_email.subject
          assert_equal "new@email.com", confirmation_email.to.first

          email_changed_notification = ActionMailer::Base.deliveries.last
          assert_match /Your .* Signon development email address is being changed/, email_changed_notification.subject
          assert_equal "old@email.com", email_changed_notification.to.first
        end
      end

      should "log an event" do
        put :update_email, id: @user.id, user: { email: "new@email.com" }
        assert_equal 1, EventLog.where(event_id: EventLog::EMAIL_CHANGE_INITIATED.id, uid: @user.uid, initiator_id: @user.id).count
      end
    end
  end

  context "PUT resend_email_change" do
    should "send an email change confirmation email" do
      perform_enqueued_jobs do
        @user = create(:user_with_pending_email_change)
        sign_in @user

        put :resend_email_change, id: @user.id

        assert_equal "Confirm your email change", ActionMailer::Base.deliveries.last.subject
      end
    end

    should "use a new token if it's expired" do
      perform_enqueued_jobs do
        @user = create(:user_with_pending_email_change,
                        confirmation_token: "old token",
                        confirmation_sent_at: 15.days.ago)
        sign_in @user

        put :resend_email_change, id: @user.id

        assert_not_equal "old token", @user.reload.confirmation_token
      end
    end
  end

  context "DELETE cancel_email_change" do
    setup do
      @user = create(:user_with_pending_email_change)
      sign_in @user
      request.env["HTTP_REFERER"] = edit_email_or_passphrase_user_path(@user)
    end

    should "clear the unconfirmed_email and the confirmation_token" do
      delete :cancel_email_change, id: @user.id

      @user.reload
      assert_equal nil, @user.unconfirmed_email
      assert_equal nil, @user.confirmation_token
    end

    should "redirect to the user edit email or passphrase page" do
      delete :cancel_email_change, id: @user.id
      assert_redirected_to edit_email_or_passphrase_user_path(@user)
    end
  end

  context "GET show (as OAuth client application)" do
    setup do
      @application = create(:application)
    end

    should "fetching json profile with a valid oauth token should succeed" do
      user = create(:user)
      user.grant_application_permission(@application, 'signin')
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {client_id: @application.uid, format: :json}

      assert_equal "200", response.code
      presenter = UserOAuthPresenter.new(user, @application)
      assert_equal presenter.as_hash.to_json, response.body
    end

    should "fetching json profile with a valid oauth token, but no client_id should succeed" do
      # For now.  Once gds-sso is updated everywhere, this will 401.

      user = create(:user)
      user.grant_application_permission(@application, 'signin')
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {format: :json}

      assert_equal "200", response.code
      presenter = UserOAuthPresenter.new(user, @application)
      assert_equal presenter.as_hash.to_json, response.body
    end

    should "fetching json profile with an invalid oauth token should not succeed" do
      user = create(:user)
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token.sub(/[0-9]/, 'x')}"
      get :show, {client_id: @application.uid, format: :json}

      assert_equal "401", response.code
    end

    should "fetching json profile with a token for another app should not succeed" do
      other_application = create(:application)
      user = create(:user)
      token = create(:access_token, application: other_application, resource_owner_id: user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token.sub(/[0-9]/, 'x')}"
      get :show, {client_id: @application.uid, format: :json}

      assert_equal "401", response.code
    end

    should "fetching json profile without any bearer header should not succeed" do
      get :show, {client_id: @application.uid, format: :json}
      assert_equal "401", response.code
    end

    should "fetching json profile should include permissions" do
      user = create(:user, with_signin_permissions_for: [@application])
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {client_id: @application.uid, format: :json}
      json = JSON.parse(response.body)
      assert_equal(["signin"], json['user']['permissions'])
    end

    should "fetching json profile should include only permissions for the relevant app" do
      other_application = create(:application)
      user = create(:user, with_signin_permissions_for: [@application, other_application])

      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {client_id: @application.uid, format: :json}
      json = JSON.parse(response.body)
      assert_equal(["signin"], json['user']['permissions'])
    end

    should "fetching json profile should update last_synced_at for the relevant app" do
      user = create(:user)
      user.grant_application_permission(@application, 'signin')
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {client_id: @application.uid, format: :json}

      assert_not_nil user.application_permissions.first.last_synced_at
    end

    should "fetching json profile should succeed even if no permission for relevant app" do
      user = create(:user)
      token = create(:access_token, application: @application, resource_owner_id: user.id)

      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{token.token}"
      get :show, {client_id: @application.uid, format: :json}

      assert_response :ok
    end
  end

  context "as Admin" do
    setup do
      @user = create(:admin_user, email: "admin@gov.uk")
      sign_in @user
    end

    context "GET index" do
      should "list users" do
        create(:user, email: "another_user@email.com")
        get :index
        assert_select "td.email", /another_user@email.com/
      end

      should "not list api users" do
        create(:api_user, email: "api_user@email.com")
        get :index
        assert_select "td.email", count: 0, text: /api_user@email.com/
      end

      should "not show superadmin users" do
        create(:superadmin_user, email: "superadmin@email.com")

        get :index

        assert_select "tbody tr", count: 1
        assert_select "td.email", /#{@user.email}/
      end

      should "show user roles" do
        create(:user, email: "user@email.com")
        create(:organisation_admin, email: "orgadmin@email.com")

        get :index

        assert_select "td.role", "Normal"
        assert_select "td.role", "Organisation admin"
        assert_select "td.role", "Admin"
        assert_select "td.role", count: 3
      end

      should "show user organisation" do
        user = create(:user_in_organisation)

        get :index

        assert_select "td.organisation", user.organisation.name
      end

      context "CSV export" do
        should "respond to CSV format" do
          get :index, format: :csv
          assert_response :success
          assert_equal @response.content_type, 'text/csv'
        end

        should "export filtered users" do
          user = create(:user)
          get :index, role: 'admin', format: :csv
          lines = @response.body.lines
          assert_equal(2, lines.length)
        end

        should "export all users when no filter selected" do
          user = create(:user)
          get :index, format: :csv
          lines = @response.body.lines
          assert_equal(3, lines.length)
        end
      end

      should "let you paginate by the first letter of the name" do
        create(:user, name: "alf", email: "a@email.com")
        create(:user, name: "zed", email: "z@email.com")

        get :index, letter: "Z"

        assert_select "td.email", /z@email.com/
        assert_select "tbody tr", count: 1
      end

      context "filter" do
        setup do
          create(:user, email: "not_admin@gov.uk")
        end

        should "filter results to users where their name or email contains the string" do
          create(:user, email: "special@gov.uk")
          create(:user, name: "Someone special", email: "someone@gov.uk")

          get :index, filter: "special"

          assert_select "tbody tr", count: 2
          assert_select "td.email", /special@gov.uk/
          assert_select "td.email", /someone@gov.uk/
        end

        should "scope list of users by role" do
          get :index, role: "normal"

          assert_select "tbody tr", count: 1
          assert_select "td.email", /admin@gov.uk/
        end

        should "scope filtered list of users by role" do
          create(:organisation_admin, email: "xyz@gov.uk")

          get :index, filter: "admin", role: "admin"

          assert_select "tbody tr", count: 1
          assert_select "td.email", /admin@gov.uk/
        end
      end

      should "scope list of users by status" do
        create(:suspended_user, email: "suspended_user@gov.uk")

        get :index, status: 'suspended'

        assert_select "tbody tr", count: 1
        assert_select "td.email", /suspended_user@gov.uk/
      end

      should "scope list of users by status and role" do
        create(:suspended_user, email: "suspended_user@gov.uk", role: 'admin')
        create(:suspended_user, email: "normal_suspended_user@gov.uk")

        get :index, status: 'suspended', role: 'admin'

        assert_select "tbody tr", count: 1
        assert_select "td.email", /suspended_user@gov.uk/
      end

      should "scope list of users by organisation" do
        user = create(:user_in_organisation, email: "orgmember@gov.uk")

        get :index, organisation: user.organisation.id

        assert_select "tbody tr", count: 1
        assert_select "td.email", /orgmember@gov.uk/
      end

      context "as superadmin" do
        should "not list api users" do
          @user.update_column(:role, "superadmin")
          create(:api_user, email: "api_user@email.com")

          get :index

          assert_select "td.email", count: 0, text: /api_user@email.com/
        end
      end
    end

    context "GET edit" do
      should "show the form" do
        not_an_admin = create(:user)
        get :edit, id: not_an_admin.id
        assert_select "input[name='user[email]'][value='#{not_an_admin.email}']"
      end

      should "show the pending email if applicable" do
        another_user = create(:user_with_pending_email_change)
        get :edit, id: another_user.id
        assert_select "input[name='user[unconfirmed_email]'][value='#{another_user.unconfirmed_email}']"
      end

      should "show the organisation to which the user belongs" do
        user_in_org = create(:user_in_organisation)
        org_with_user = user_in_org.organisation
        other_organisation = create(:organisation, abbreviation: 'ABBR')

        get :edit, id: user_in_org.id

        assert_select "select[name='user[organisation_id]']" do
          assert_select "option", count: 3
          assert_select "option[selected=selected]", count: 1
          assert_select %{option[value="#{org_with_user.id}"][selected=selected]}, text: org_with_user.name_with_abbreviation
          assert_select %{option[value="#{other_organisation.id}"]}, text: other_organisation.name_with_abbreviation
        end
      end

      should "not be able to edit superadmins" do
        superadmin = create(:superadmin_user)

        get :edit, id: superadmin.id

        assert_redirected_to root_path
        assert_match(/You do not have permission to perform this action./, flash[:alert])
      end

      context "organisation admin" do
        should "not be able to assign organisations outside their organisation subtree" do
          admin = create(:organisation_admin)
          outside_organisation = create(:organisation)
          sign_in admin

          user = create(:user_in_organisation, organisation: admin.organisation)
          assert_not_nil user.organisation

          get :edit, id: user.id

          assert_select ".container" do
            assert_select "option", count: 0, text: outside_organisation.name_with_abbreviation
          end
        end

        should "be able to assign organisations within their organisation subtree" do
          admin = create(:organisation_admin)
          sub_organisation = create(:organisation, parent: admin.organisation)
          sign_in admin

          user = create(:user_in_organisation, organisation: sub_organisation)
          assert_not_nil user.organisation

          get :edit, id: user.id

          assert_select ".container" do
            assert_select "option", count: 1, text: sub_organisation.name_with_abbreviation
            assert_select "option", count: 1, text: admin.organisation.name_with_abbreviation
          end
        end
      end
    end

    context "PUT update" do
      should "update the user" do
        another_user = create(:user, name: "Old Name")
        put :update, id: another_user.id, user: { name: "New Name" }

        assert_equal "New Name", another_user.reload.name
        assert_redirected_to users_path
        assert_equal "Updated user #{another_user.email} successfully", flash[:notice]
      end

      should "not be able to update superadmins" do
        superadmin = create(:superadmin_user)

        put :edit, id: superadmin.id, user: { email: 'normal_user@example.com' }

        assert_redirected_to root_path
        assert_match(/You do not have permission to perform this action./, flash[:alert])
      end

      should "update the user's organisation" do
        user = create(:user_in_organisation)

        assert_not_nil user.organisation
        put :update, id: user.id, user: { organisation_id: nil }
        assert_nil user.reload.organisation
      end

      context "organisation admin" do
        should "be able to assign organisations under their organisation subtree" do
          admin = create(:organisation_admin)
          sub_organisation = create(:organisation, parent: admin.organisation)
          sign_in admin

          user = create(:user_in_organisation, organisation: sub_organisation)
          assert_not_nil user.organisation

          put :update, id: user.id, user: { organisation_id: admin.organisation.id }
          assert_equal admin.organisation.id, user.reload.organisation.id
        end

        should "not be able to assign organisations outside their organisation subtree" do
          admin = create(:organisation_admin)
          outside_organisation = create(:organisation)
          sign_in admin

          user = create(:user_in_organisation, organisation: admin.organisation)
          assert_not_nil user.organisation

          put :update, id: user.id, user: { organisation_id: outside_organisation.id }
          assert_not_equal outside_organisation.id, user.reload.organisation.id
        end
      end

      should "redisplay the form if save fails" do
        another_user = create(:user)
        put :update, id: another_user.id, user: { name: "" }
        assert_select "form#edit_user_#{another_user.id}"
      end

      should "not let you set the role" do
        not_an_admin = create(:user)
        put :update, id: not_an_admin.id, user: { role: "admin" }
        assert_equal "normal", not_an_admin.reload.role
      end

      context "you are a superadmin" do
        setup do
          @user.update_column(:role, "superadmin")
        end

        should "let you set the role" do
          not_an_admin = create(:user)
          put :update, id: not_an_admin.id, user: { role: "admin" }
          assert_equal "admin", not_an_admin.reload.role
        end
      end

      context "changing an email" do
        should "not re-confirm email" do
          normal_user = create(:user, email: "old@email.com")
          put :update, id: normal_user.id, user: { email: "new@email.com" }

          assert_nil normal_user.reload.unconfirmed_email
          assert_equal "new@email.com", normal_user.email
        end

        should "log an event" do
          normal_user = create(:user, email: "old@email.com")
          put :update, id: normal_user.id, user: { email: "new@email.com" }

          assert_equal 1, EventLog.where(event_id: EventLog::EMAIL_CHANGED.id, uid: normal_user.uid, initiator_id: @user.id).count
        end

        should "send email change notifications to old and new email address" do
          perform_enqueued_jobs do
            normal_user = create(:user, email: "old@email.com")
            put :update, id: normal_user.id, user: { email: "new@email.com" }

            email_change_notifications = ActionMailer::Base.deliveries[-2..-1]
            assert_equal email_change_notifications.map(&:subject).uniq.count, 1
            assert_match /Your .* Signon development email address has been updated/, email_change_notifications.map(&:subject).first
            assert_equal %w(old@email.com new@email.com), email_change_notifications.map {|mail| mail.to.first }
          end
        end

        context "an invited-but-not-yet-accepted user" do
          should "change the email, and send an invitation email" do
            perform_enqueued_jobs do
              another_user = User.invite!(name: "Ali", email: "old@email.com")
              put :update, id: another_user.id, user: { email: "new@email.com" }

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

        put :update, id: another_user.id, user: { name: "New Name" }
      end
    end

    context "PUT resend_email_change" do
      should "send an email change confirmation email" do
        perform_enqueued_jobs do
          another_user = create(:user_with_pending_email_change)
          put :resend_email_change, id: another_user.id

          assert_equal "Confirm your email change", ActionMailer::Base.deliveries.last.subject
        end
      end

      should "use a new token if it's expired" do
        another_user = create(:user_with_pending_email_change,
                                confirmation_token: "old token",
                                confirmation_sent_at: 15.days.ago)
        put :resend_email_change, id: another_user.id

        assert_not_equal "old token", another_user.reload.confirmation_token
      end
    end

    context "DELETE cancel_email_change" do
      setup do
        @another_user = create(:user_with_pending_email_change)
        request.env["HTTP_REFERER"] = edit_user_path(@another_user)
      end

      should "clear the unconfirmed_email and the confirmation_token" do
        delete :cancel_email_change, id: @another_user.id

        @another_user.reload
        assert_nil @another_user.unconfirmed_email
        assert_nil @another_user.confirmation_token
      end

      should "redirect to the edit user admin page" do
        delete :cancel_email_change, id: @another_user.id
        assert_redirected_to edit_user_path(@another_user)
      end
    end

    should "disallow access to non-admins" do
      @user.update_column(:role, 'normal')
      get :index
      assert_redirected_to root_path
    end
  end
end
