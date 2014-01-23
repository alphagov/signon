require 'test_helper'
require 'sidekiq/testing'
 
class BatchInvitingUsersTest < ActionDispatch::IntegrationTest
  include EmailHelpers

  should "create users whose details are specified in a CSV file" do
    Sidekiq::Testing.inline! do
      user = create(:user, role: "admin")
      visit root_path
      signin(user)

      visit new_admin_batch_invitation_path
      path = File.join(::Rails.root, "test", "fixtures", "users.csv")
      attach_file("Choose a CSV file of users with names and email addresses", path)
      click_button "Create users and send emails"

      assert_response_contains("Creating a batch of users")
      assert_response_contains("1 users processed")

      assert_not_nil User.find_by_email("fred@example.com")
      assert_equal "fred@example.com", last_email.to[0]
      assert_match 'Please confirm your account', last_email.subject
    end
  end
end
