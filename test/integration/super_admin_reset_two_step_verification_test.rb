require 'test_helper'

class SuperAdminResetTwoStepVerificationTest < ActionDispatch::IntegrationTest
  include EmailHelpers
  include ActiveJob::TestHelper

  setup do
    @user = create(:user, otp_secret_key: 'sekret')
  end

  context 'when logged in as a regular admin' do
    setup do
      @admin = create(:admin_user)

      visit edit_user_path(@user)
      signin(@admin)
    end

    should 'not display the link' do
      assert page.has_no_link? 'Reset 2-step verification'
    end
  end

  context 'when logged in as a super admin' do
    setup do
      @super_admin = create(:superadmin_user)

      use_javascript_driver
      visit edit_user_path(@user)
      signin(@super_admin)
    end

    should 'reset 2-step verification and notify the chosen user by email' do
      perform_enqueued_jobs do
        assert_response_contains '2-step verification enabled'

        click_link 'Reset 2-step verification'

        assert_response_contains '2-step verification is now reset'

        assert last_email
        assert_equal '2-step verification has been reset', last_email.subject
      end
    end
  end
end
