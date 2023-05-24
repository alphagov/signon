require "test_helper"

class TwoStepVerificationControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @controller = Devise::TwoStepVerificationController.new

    @user = create(:user)
    sign_in @user
  end

  context "when user is not logged in" do
    setup { sign_out @user }

    should "redirect to login upon attempted prompt" do
      get :prompt

      assert_redirected_to new_user_session_path
    end
  end

  context "when MFA code is required by login journey" do
    setup do
      sign_out @user
      sign_in @user, passed_mfa: false
    end

    should "redirect to login upon attempted prompt" do
      get :prompt

      assert_redirected_to new_two_step_verification_session_path
    end
  end
end
