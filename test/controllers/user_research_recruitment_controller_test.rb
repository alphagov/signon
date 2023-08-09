require "test_helper"

class UserResearchRecruitmentControllerTest < ActionController::TestCase
  attr_reader :choice

  context "#update" do
    context "when user clicks the button to dismiss the banner" do
      setup do
        @choice = "dismiss-banner"
      end

      should "require signed in users" do
        put :update, params: { choice: }

        assert_redirected_to new_user_session_path
      end

      should "set session cookie" do
        sign_in create(:user)

        put :update, params: { choice: }

        assert cookies[:dismiss_user_research_recruitment_banner]
      end

      should "redirect to root path" do
        sign_in create(:user)

        put :update, params: { choice: }

        assert_redirected_to root_path
      end
    end
  end
end
