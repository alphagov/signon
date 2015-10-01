require 'test_helper'

class TwoStepVerificationPromptTest < ActionDispatch::IntegrationTest
  context 'when the user has been flagged for 2-step verification' do
    setup do
      user = create(:two_step_flagged_user)
      visit root_path
      signin(user)
    end

    should 'prompt the user to complete verification' do
      assert page.has_text?('Setup 2-step verification?')
    end
  end
end
