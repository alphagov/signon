require 'test_helper'

class SignOutTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email: "email@example.com", password: "some passphrase with various $ymb0l$")
    visit root_path
    signin(@user)
  end

  should "perform reauth on downstream apps" do
    ReauthEnforcer.expects(:perform_on).with(@user).once

    within("div.container[role=main]") do
      click_link "Sign out"
    end
    assert_response_contains("Signed out successfully.")
  end
end
