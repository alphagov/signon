require 'test_helper'

class SuperAdminFlaggingTwoStepVerificationTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ActiveJob::TestHelper

  context 'flagging an existing user for two step verification' do
    should 'notify the user by email' do
      perform_enqueued_jobs do
        super_admin = create(:superadmin_user)
        user = create(:user)
        visit root_path
        signin(super_admin)

        visit edit_user_path(user)
        check 'Ask user to set up 2-step verification'
        click_button 'Update User'

        assert last_email
        assert_equal 'Set up 2-step verification', last_email.subject
      end
    end
  end
end
