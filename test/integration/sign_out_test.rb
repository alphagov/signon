require "test_helper"

class SignOutTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user_in_organisation, email: "email@example.com", password: "some password with various $ymb0l$")
    visit root_path
  end

  should "perform reauth on downstream apps" do
    signin_with(@user)
    ReauthEnforcer.expects(:perform_on).with(@user)

    click_link "Sign out"

    assert_response_contains("Sign in to GOV.UK")
  end

  should "not blow up if not already signed in" do
    signout
    assert_response_contains("Sign in")
  end
end
