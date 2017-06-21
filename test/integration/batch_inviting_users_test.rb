require 'test_helper'

class BatchInvitingUsersTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  should "superadmin user can create users whose details are specified in a CSV file" do
    application = create(:application)
    user = create(:superadmin_user)

    perform_batch_invite_with_user(user, application)
  end

  should "admin user can create users whose details are specified in a CSV file" do
    application = create(:application)
    user = create(:admin_user)

    perform_batch_invite_with_user(user, application)
  end

  should "organisation admin user can not create users whose details are specified in a CSV file" do
    application = create(:application)
    user = create(:user_in_organisation, role: 'organisation_admin')
    user.grant_application_permission(application, ['signin'])

    visit root_path
    signin_with(user)

    visit new_batch_invitation_path
    assert_equal root_path, current_path
  end

  def perform_batch_invite_with_user(user, application)
    perform_enqueued_jobs do
      visit root_path
      signin_with(user)

      visit new_batch_invitation_path
      path = File.join(::Rails.root, "test", "fixtures", "users.csv")
      attach_file("Choose a CSV file of users with names and email addresses", path)
      check "Has access to #{application.name}?"
      click_button "Create users and send emails"

      assert_response_contains("Creating a batch of users")
      assert_response_contains("1 users processed")

      invited_user = User.find_by_email("fred@example.com")
      assert_not_nil invited_user
      assert invited_user.has_access_to?(application)
      assert_equal "noreply-signon-development@digital.cabinet-office.gov.uk", last_email.from[0]
      assert_equal nil, last_email.reply_to[0]

      assert_equal "fred@example.com", last_email.to[0]
      assert_match 'Please confirm your account', last_email.subject
    end
  end
end
