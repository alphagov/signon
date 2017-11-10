require 'test_helper'

class InvitingUsersTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ActiveJob::TestHelper

  should "send the user an invitation token" do
    user = User.invite!(name: "Jim", email: "jim@web.com")
    visit accept_user_invitation_path(invitation_token: user.raw_invitation_token)

    fill_in "New passphrase", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    fill_in "Confirm new passphrase", with: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z"
    click_button "Set my passphrase"

    assert_response_contains("You are now signed in")
  end

  context "for non-superadmins" do
    should "not display the 2SV flagging checkbox" do
      admin = create(:admin_user)
      visit root_path
      signin_with(admin)

      visit new_user_invitation_path

      assert has_no_field?("Require 2-step verification")
    end
  end

  context "for an end-user by an admin" do
    setup do
      admin = create(:user, role: "admin")
      visit root_path
      signin_with(admin)
    end

    should "create and notify the user" do
      perform_enqueued_jobs do
        visit new_user_invitation_path
        fill_in "Name", with: "Fred Bloggs"
        fill_in "Email", with: "fred@example.com"
        click_button "Create user and send email"

        assert_not_nil User.where(email: "fred@example.com", role: "normal").first
        assert_equal "fred@example.com", last_email.to[0]
        assert_match 'Please confirm your account', last_email.subject
      end
    end

    should "grant the user any default permissions" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: 'editor', default: true)
      application_two = create(:application)
      application_two.signin_permission.update_attributes(default: true)

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"
      click_button "Create user and send email"

      u = User.find_by(email: 'alicia@example.com')
      assert u.has_access_to? application_two
      assert_equal ['editor'], u.permissions_for(application_one)
    end

    should "show an error message when attempting to create a user without an email" do
      visit new_user_invitation_path
      fill_in "Name", with: "Fred Bloggs"
      click_button "Create user and send email"

      assert_response_contains("Email can't be blank")
    end
  end

  context "for an admin by a superadmin" do
    setup do
      admin = create(:user, role: "superadmin")
      visit root_path
      signin_with(admin)
    end

    should "create and notify the admin" do
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
          require_2sv: true
        )
        assert_equal "fred_admin@example.com", last_email.to[0]
        assert_match 'Please confirm your account', last_email.subject
      end
    end

    should "grant the user any default permissions" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: 'editor', default: true)
      application_two = create(:application)
      application_two.signin_permission.update_attributes(default: true)

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"
      click_button "Create user and send email"

      u = User.find_by(email: 'alicia@example.com')
      assert u.has_access_to? application_two
      assert_equal ['editor'], u.permissions_for(application_one)
    end
  end

  context "a normal user being invited by an admin" do
    setup do
      admin = create(:admin_user)
      visit root_path
      signin_with(admin)
    end

    should "create and notify the user" do
      perform_enqueued_jobs do
        visit new_user_invitation_path
        assert has_no_select?("Role")
        fill_in "Name", with: "Fred Bloggs"
        fill_in "Email", with: "normal_fred@example.com"
        click_button "Create user and send email"

        assert_not_nil User.where(email: "normal_fred@example.com", role: "normal").first
        assert_equal "normal_fred@example.com", last_email.to[0]
        assert_match 'Please confirm your account', last_email.subject
      end
    end

    should "grant the user any default permissions" do
      application_one = create(:application)
      create(:supported_permission, application: application_one, name: 'editor', default: true)
      application_two = create(:application)
      application_two.signin_permission.update_attributes(default: true)

      visit new_user_invitation_path
      fill_in "Name", with: "Alicia Smith"
      fill_in "Email", with: "alicia@example.com"
      click_button "Create user and send email"

      u = User.find_by(email: 'alicia@example.com')
      assert u.has_access_to? application_two
      assert_equal ['editor'], u.permissions_for(application_one)
    end
  end
end
