require 'test_helper'

class TwoStepVerificationPromptTest < ActionDispatch::IntegrationTest
  context 'when the user has been flagged for 2-step verification' do
    setup do
      @user = create(:two_step_flagged_user)
      visit users_path
      signin_with(@user, set_up_2sv: false)
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

    context 'when they try to access something else' do
      should 'ensure the prompt is still displayed' do
        visit users_path

        assert page.has_text?('Start set up')
      end
    end

    context 'they choose to setup 2-step verification' do
      should 'direct them to setup' do
        secret = ROTP::Base32.random_base32
        ROTP::Base32.stubs(random_base32: secret)

        click_link 'Start set up'

        assert page.has_text?('Set up 2-step verification')

        enter_2sv_code(secret)

        assert_equal users_path, current_path
      end
    end

    context 'before the 2SV hard go live date' do
      should 'display the go live disclaimer' do
        travel_to User::TWO_STEP_GO_LIVE_DATE - 1 do
          visit users_path
          signin_with(@user, set_up_2sv: false)

          assert page.has_text?('From Friday 20 November')
        end
      end
    end

    context 'after the 2SV hard go live date' do
      should 'not permit deferral or display go live disclaimer' do
        travel_to User::TWO_STEP_GO_LIVE_DATE do
          visit users_path
          signin_with(@user, set_up_2sv: false)

          assert page.has_link?('Start set up')
          assert page.has_no_button?('Not now')
          assert page.has_no_text?('From Friday 20 November')
        end
      end
    end
  end
end
