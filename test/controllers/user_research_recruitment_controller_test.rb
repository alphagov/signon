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

  test "#participate requires users to be signed in" do
    post :participate

    assert_redirected_to new_user_session_path
  end

  test "#participate sets user_research_recruitment_banner_hidden to true for the current_user" do
    user = create(:user)
    sign_in user

    post :participate

    assert user.user_research_recruitment_banner_hidden?
  end

  test "#participate redirects to the google form" do
    sign_in create(:user)

    post :participate

    assert_redirected_to UserResearchRecruitmentController::USER_RESEARCH_RECRUITMENT_FORM_URL
  end
end
