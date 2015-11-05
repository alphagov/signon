require 'test_helper'
require 'helpers/passphrase_support'

class UserStatusTest < ActionDispatch::IntegrationTest
  include PassPhraseSupport

  setup do
    @admin = create(:admin_user)
    @user = create(:user, password_changed_at: 91.days.ago)
  end

  test "User status appears on the edit user page" do
    visit root_path
    signin_with(@admin)
    visit user_path(@user)

    assert page.has_content?("User passphrase expired")
  end
end
