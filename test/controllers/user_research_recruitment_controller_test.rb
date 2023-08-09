require "test_helper"

class UserResearchRecruitmentControllerTest < ActionController::TestCase
  attr_reader :choice

  context "#update" do
    should "require users to be signed in" do
      put :update

      assert_redirected_to new_user_session_path
    end

    context "when user clicks the button to dismiss the banner" do
      setup do
        @choice = "dismiss-banner"
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

    context "when user clicks the button to participate in user research" do
      setup do
        @choice = "participate"
      end

      should "set user_research_recruitment_banner_hidden to true for the current_user" do
        user = create(:user)
        sign_in user

        put :update, params: { choice: }

        assert user.user_research_recruitment_banner_hidden?
      end

      should "redirect to the Google Form" do
        sign_in create(:user)

        put :update, params: { choice: }

        assert_redirected_to UserResearchRecruitmentController::USER_RESEARCH_RECRUITMENT_FORM_URL
      end
    end
  end
end
