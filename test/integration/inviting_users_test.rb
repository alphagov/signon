require "test_helper"

class InvitingUsersTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ActiveJob::TestHelper

  should "send the user an invitation token" do
    user = User.invite!(name: "Jim", email: "jim@web.com")
    visit accept_user_invitation_path(invitation_token: user.raw_invitation_token)

    fill_in "New password", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    fill_in "Confirm new password", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    click_button "Save password"

    assert_response_contains("You are now signed in")
  end

  should "not send invitation token to Google Analytics" do
    user = User.invite!(name: "Jim", email: "jim@web.com")
    visit accept_user_invitation_path(invitation_token: user.raw_invitation_token, foo: "bar")

    query = URI(google_analytics_page_view_path).query
    params = Rack::Utils.parse_nested_query(query)

    assert_not params.keys.include?("invitation_token")
    assert params.keys.include?("foo")
  end

  context "as an admin" do
    setup do
      admin = create(:user, role: "admin")
      visit root_path
      signin_with(admin)
    end

    should "not present the role selector" do
      visit new_user_invitation_path
      assert has_no_select?("Role")
    end

    context "for an organisation without mandatory 2SV" do
      setup do
        create(:organisation, name: "Test Organisation without 2SV", require_2sv: false)
      end

      should "create and notify the user with 2SV selected" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_equal "fred@example.com", last_email.to[0]
          assert_match "Please confirm your account", last_email.subject

          assert has_field?("Mandate 2-step verification for this user")
          check "Mandate 2-step verification for this user"
          click_button "Update user"

          assert_not_nil User.where(email: "fred@example.com", role: "normal").last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match "Make your Signon account more secure", last_email.subject
          assert User.where(email: "fred@example.com", role: "normal").last.require_2sv?
        end
      end

      should "create and notify the user without 2SV selected" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert has_field?("Mandate 2-step verification for this user")
          click_button "Update user"

          assert_not_nil User.where(email: "fred@example.com", role: "normal").last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match "Please confirm your account", last_email.subject
          assert_equal false, User.where(email: "fred@example.com", role: "normal").last.require_2sv?
        end
      end

      context "for an organisation with mandatory 2SV" do
        setup do
          create(:organisation, name: "Test Organisation with 2SV", require_2sv: true)
        end

        should "create and notify the user" do
          perform_enqueued_jobs do
            visit new_user_invitation_path
            fill_in "Name", with: "Fred Bloggs"
            fill_in "Email", with: "fred@example.com"
            select "Test Organisation with 2SV", from: "Organisation"
            click_button "Create user and send email"

            assert_not_nil User.where(email: "fred@example.com", role: "normal").last
            assert_equal "fred@example.com", last_email.to[0]
            assert_match "Please confirm your account", last_email.subject
            assert User.where(email: "fred@example.com", role: "normal").last.require_2sv?
          end
        end
      end
    end

    should "resend the invite" do
      perform_enqueued_jobs do
        visit new_user_invitation_path
        fill_in "Name", with: "Fred Bloggs"
        fill_in "Email", with: "fred@example.com"
        click_button "Create user and send email"

        click_button "Update user"

        user = User.find_by(email: "fred@example.com")
        visit edit_user_path(user)

        click_button "Resend signup email"

        assert page.has_content?("Resent account signup email")
        emails_received = all_emails.count { |email| email.subject == "Please confirm your account" }
        assert_equal 2, emails_received
      end
    end

    should "grant the permissions selected" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: "editor")
      application_two = create(:application)
      create(:supported_permission, application: application_two, name: "gds-admin")

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"

      uncheck "Has access to #{application_one.name}?"
      check "Has access to #{application_two.name}?"
      select "editor", from: "Permissions for #{application_one.name}"
      unselect "gds-admin", from: "Permissions for #{application_two.name}"

      click_button "Create user and send email"

      click_button "Update user"

      u = User.find_by(email: "alicia@example.com")
      assert_not u.has_access_to? application_one
      assert_includes u.permissions_for(application_one), "editor"
      assert u.has_access_to? application_two
      assert_not_includes u.permissions_for(application_two), "gds-admin"
    end

    should "grant the user any default permissions" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: "editor", default: true)
      application_two = create(:application)
      application_two.signin_permission.update!(default: true)

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"
      click_button "Create user and send email"

      click_button "Update user"

      u = User.find_by(email: "alicia@example.com")
      assert u.has_access_to? application_two
      assert_equal %w[editor], u.permissions_for(application_one)
    end

    should "show an error message when attempting to create a user without an email" do
      visit new_user_invitation_path
      fill_in "Name", with: "Fred Bloggs"
      click_button "Create user and send email"

      assert_response_contains("Email can't be blank")
    end
  end

  context "as a superadmin" do
    setup do
      superadmin = create(:user, role: "superadmin")
      visit root_path
      signin_with(superadmin)
    end

    should "present the role selector" do
      visit new_user_invitation_path
      assert has_select?("Role")
    end

    context "for roles that do not have mandatory 2SV" do
      should "create and notify the user" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred_admin@example.com"
          click_button "Create user and send email"

          assert_equal "fred_admin@example.com", last_email.to[0]
          assert_match "Please confirm your account", last_email.subject

          assert has_field?("Mandate 2-step verification for this user")
          check "Mandate 2-step verification for this user"
          click_button "Update user"

          assert_not_nil User.find_by(
            email: "fred_admin@example.com",
            role: "normal",
            require_2sv: true,
          )
          assert_equal "fred_admin@example.com", last_email.to[0]
          assert_match "Make your Signon account more secure", last_email.subject
        end
      end
    end

    context "for user roles that have mandatory 2SV" do
      setup do
        create(:organisation, name: "Test Organisation without 2SV", require_2sv: false)
      end

      should "create and notify the user for a superadmin" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Superadmin", from: "Role"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_not_nil User.where(email: "fred@example.com", role: "superadmin").last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match "Please confirm your account", last_email.subject
          assert User.where(email: "fred@example.com", role: "superadmin").last.require_2sv?
        end
      end

      should "create and notify the user for an admin" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Admin", from: "Role"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_not_nil User.where(email: "fred@example.com", role: "admin").last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match "Please confirm your account", last_email.subject
          assert User.where(email: "fred@example.com", role: "admin").last.require_2sv?
        end
      end
    end

    context "for user roles that have mandatory 2SV" do
      setup do
        create(:organisation, name: "Test Organisation without 2SV", require_2sv: false)
      end

      should "create and notify the user for a superadmin" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Superadmin", from: "Role"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_not_nil User.where(email: "fred@example.com", role: "superadmin").last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match "Please confirm your account", last_email.subject
          assert User.where(email: "fred@example.com", role: "superadmin").last.require_2sv?
        end
      end

      should "create and notify the user for an admin" do
        perform_enqueued_jobs do
          visit new_user_invitation_path
          fill_in "Name", with: "Fred Bloggs"
          fill_in "Email", with: "fred@example.com"
          select "Admin", from: "Role"
          select "Test Organisation without 2SV", from: "Organisation"
          click_button "Create user and send email"

          assert_not_nil User.where(email: "fred@example.com", role: "admin").last
          assert_equal "fred@example.com", last_email.to[0]
          assert_match "Please confirm your account", last_email.subject
          assert User.where(email: "fred@example.com", role: "admin").last.require_2sv?
        end
      end
    end

    should "grant the permissions selected" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: "editor")
      application_two = create(:application)
      create(:supported_permission, application: application_two, name: "gds-admin")

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"

      uncheck "Has access to #{application_one.name}?"
      check "Has access to #{application_two.name}?"
      select "editor", from: "Permissions for #{application_one.name}"
      unselect "gds-admin", from: "Permissions for #{application_two.name}"

      click_button "Create user and send email"

      click_button "Update user"

      u = User.find_by(email: "alicia@example.com")
      assert_not u.has_access_to? application_one
      assert_includes u.permissions_for(application_one), "editor"
      assert u.has_access_to? application_two
      assert_not_includes u.permissions_for(application_two), "gds-admin"
    end

    should "grant the user any default permissions" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: "editor", default: true)
      application_two = create(:application)
      application_two.signin_permission.update!(default: true)

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"
      click_button "Create user and send email"

      check "Mandate 2-step verification for this user"
      click_button "Update user"

      u = User.find_by(email: "alicia@example.com")
      assert u.has_access_to? application_two
      assert_equal %w[editor], u.permissions_for(application_one)
    end
  end

  context "Notify service is using an allowlist or is in trial mode" do
    setup do
      admin = create(:user, role: "admin")
      visit root_path
      signin_with(admin)
    end

    should "raise an error if email address is not in Notify team" do
      response = stub("response", code: 400, body: "Can't send to this recipient using a team-only API key")
      User.stubs(:invite!).raises(Notifications::Client::BadRequestError, response)

      perform_enqueued_jobs do
        visit new_user_invitation_path
        fill_in "Name", with: "Fred Bloggs"
        fill_in "Email", with: "fred@example.com"
        click_button "Create user and send email"

        assert_response_contains "Error: One or more recipients not in GOV.UK Notify team (code: 400)"
      end
    end
  end
end
