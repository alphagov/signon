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

    should "not display the 2SV flagging checkbox" do
      visit new_user_invitation_path
      assert has_no_field?("Ask user to set up 2-step verification")
    end

    should "create and notify the user" do
      perform_enqueued_jobs do
        visit new_user_invitation_path
        fill_in "Name", with: "Fred Bloggs"
        fill_in "Email", with: "fred@example.com"
        click_button "Create user and send email"

        assert_not_nil User.where(email: "fred@example.com", role: "normal").first
        assert_equal "fred@example.com", last_email.to[0]
        assert_match "Please confirm your account", last_email.subject
      end
    end

    should "resend the invite" do
      perform_enqueued_jobs do
        visit new_user_invitation_path
        fill_in "Name", with: "Fred Bloggs"
        fill_in "Email", with: "fred@example.com"
        click_button "Create user and send email"

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

    should "display the 2SV flagging checkbox" do
      visit new_user_invitation_path
      assert has_field?("Ask user to set up 2-step verification")
    end

    should "create and notify the user" do
      perform_enqueued_jobs do
        visit new_user_invitation_path
        fill_in "Name", with: "Fred Bloggs"
        select "Admin", from: "Role"
        fill_in "Email", with: "fred_admin@example.com"
        check "Ask user to set up 2-step verification"
        click_button "Create user and send email"

        assert_not_nil User.find_by(
          email: "fred_admin@example.com",
          role: "admin",
          require_2sv: true,
        )
        assert_equal "fred_admin@example.com", last_email.to[0]
        assert_match "Please confirm your account", last_email.subject
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
      raises_exception = lambda do |_request, _params|
        response = MiniTest::Mock.new
        response.expect :code, 400
        response.expect :body, "Can't send to this recipient using a team-only API key"
        raise Notifications::Client::BadRequestError, response
      end

      User.stub(:invite!, raises_exception) do
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
end
