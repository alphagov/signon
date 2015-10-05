require 'test_helper'

class TwoStepVerificationPromptTest < ActionDispatch::IntegrationTest
  context 'when the user has been flagged for 2-step verification' do
    setup do
      @user = create(:two_step_flagged_user)
      visit users_path
      signin(@user)
    end

    should 'prompt the user to complete verification' do
      assert page.has_text?('Start set up')
    end

    context 'they choose to defer setup' do
      should 'redirect them to where they were headed originally' do
        click_button 'Not now'

        assert_equal users_path, page.current_path
      end
    end

    context 'they choose to setup 2-step verification' do
      should 'direct them to setup' do
        click_link 'Start set up'

        assert page.has_text?('Set up 2-step verification')
      end
    end
  end
end
