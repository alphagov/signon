require 'test_helper'

class SuperAdminDisableTwoStepVerificationTest < ActionDispatch::IntegrationTest
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
      assert page.has_no_link? 'Disable 2-step verification'
    end
  end

  context 'when logged in as a super admin' do
    setup do
      @super_admin = create(:superadmin_user)

      use_javascript_driver
      visit edit_user_path(@user)
      signin(@super_admin)
    end

    should 'disable 2-step verification for the chosen user' do
      click_link 'Disable 2-step verification'

      assert_response_contains('2-step verification is now disabled')
    end
  end
end
