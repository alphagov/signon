require "test_helper"

class Users::NameChangeTest < ActionDispatch::IntegrationTest
  context "when signed in as any kind of admin" do
    setup do
      @superadmin = create(:superadmin_user)
      @user = create(:user, name: "user-name")
    end

    should "be able to change a normal user's name" do
      visit root_path
      signin_with(@superadmin)
      visit edit_user_path(@user)
      click_link "Change Name"
      fill_in "Name", with: "new-user-name"
      click_button "Change name"
      assert_equal "new-user-name", @user.reload.name
    end
  end
end
