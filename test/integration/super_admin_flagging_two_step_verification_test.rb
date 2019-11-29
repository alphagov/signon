require "test_helper"

class SuperAdminFlaggingTwoStepVerificationTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ActiveJob::TestHelper

  context "updating a user" do
    setup do
      super_admin = create(:superadmin_user)
      user = create(:user)
      visit root_path
      signin_with(super_admin)

      visit edit_user_path(user)
    end

    context "when the user is flagged for 2SV" do
      should "notify the user by email" do
        perform_enqueued_jobs do
          check "Ask user to set up 2-step verification"
          click_button "Update User"

          assert last_email
          assert_equal "Make your Signon account more secure", last_email.subject
        end
      end
    end

    context "when the user is not flagged for 2SV" do
      should "not notify the user by email" do
        perform_enqueued_jobs do
          uncheck "Ask user to set up 2-step verification"
          click_button "Update User"

          assert_not last_email
        end
      end
    end
  end
end
