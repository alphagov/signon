require "test_helper"

class UserResearchRecruitmentBannerTest < ActionDispatch::IntegrationTest
  should "not display the banner on the login page" do
    visit new_user_session_path

    assert_not has_content?(user_research_recruitment_banner_title)
  end

  should "display the banner on the dashboard" do
    user = create(:user, name: "user-name", email: "user@example.com")
    visit new_user_session_path
    signin_with(user)

    assert has_content?(user_research_recruitment_banner_title)
    assert has_css?("form", text: "Find out more")
  end

  should "not display the banner on any page other than the dashboard" do
    user = create(:user, name: "user-name", email: "user@example.com")
    visit new_user_session_path
    signin_with(user)

    click_on "Change your email or password"

    assert_not has_content?(user_research_recruitment_banner_title)
  end

  should "hide the banner until the next session" do
    user = create(:user, name: "user-name", email: "user@example.com")

    using_session("Session 1") do
      visit new_user_session_path
      signin_with(user)

      assert has_content?(user_research_recruitment_banner_title)

      within ".user-research-recruitment-banner" do
        click_on "Hide this"
      end

      visit root_path

      assert_not has_content?(user_research_recruitment_banner_title)
    end

    using_session("Session 2") do
      visit new_user_session_path
      signin_with(user)

      assert has_content?(user_research_recruitment_banner_title)
    end
  end

private

  def user_research_recruitment_banner_title
    "Help us improve GOV.UK Publishing"
  end
end
