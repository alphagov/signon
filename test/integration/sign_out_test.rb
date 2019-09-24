require "test_helper"

class SignOutTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user_in_organisation, email: "email@example.com", password: "some password with various $ymb0l$")
    visit root_path
  end

  should "perform reauth on downstream apps" do
    signin_with(@user)
    ReauthEnforcer.expects(:perform_on).with(@user).once

    click_link "Sign out"

    assert_response_contains("Sign in to GOV.UK")
  end

  should "not blow up if not already signed in" do
    signout
    assert_response_contains("Sign in")
  end

  should "stop sending the user org slug to GA once signed out" do
    use_javascript_driver
    with_ga_enabled do
      visit root_path
      signin_with(@user)
      assert_dimension_is_set(8)

      signout
      refute_dimension_is_set(8)
    end
  end
end
