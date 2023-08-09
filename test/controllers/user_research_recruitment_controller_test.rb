require "test_helper"

class UserResearchRecruitmentControllerTest < ActionController::TestCase
  test "#dismiss_banner requires signed in users" do
    post :dismiss_banner

    assert_redirected_to new_user_session_path
  end

  test "#dismiss_banner sets session cookie" do
    sign_in create(:user)

    post :dismiss_banner

    assert cookies[:dismiss_user_research_recruitment_banner]
  end

  test "#dismiss_banner redirects to root path" do
    sign_in create(:user)

    post :dismiss_banner

    assert_redirected_to root_path
  end
end
