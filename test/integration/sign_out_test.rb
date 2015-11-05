require 'test_helper'

class SignOutTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "email@example.com", password: "some passphrase with various $ymb0l$")
    visit root_path
  end

  should "perform reauth on downstream apps" do
    signin_with(@user)
    ReauthEnforcer.expects(:perform_on).with(@user).once

    within("main") do
      click_link "Sign out"
    end
    assert_response_contains("Signed out successfully.")
  end

  should "not blow up if not already signed in" do
    signout
    assert_response_contains("Sign in")
  end
end
