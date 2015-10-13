require 'test_helper'

class SuperAdminDisableTwoStepVerificationTest < ActionDispatch::IntegrationTest
  context 'when logged in as a regular admin' do
    setup do
      @user  = create(:user)
      @admin = create(:admin_user)

      visit edit_user_path(@user)
      signin(@admin)
    end

    should 'not display the link' do
      assert page.has_no_link? 'Disable 2-step verification'
    end
  end
end
