require "test_helper"

class ChangeUserRoleTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = create(:superadmin_user)
  end

  # TODO: there's some stuff that can be refactored here - common stuff into helpers
  def sign_in_as_and_edit_user(sign_in_as, user_to_edit)
    visit root_path
    signin_with(sign_in_as)
    visit edit_user_path(user_to_edit)
  end

  context "when logged in as a super admin" do
    should "be able to change the role of a user who is not exempt from 2SV" do
      user = create(:user)
      sign_in_as_and_edit_user(@super_admin, user)
      click_link "Change role"

      select "Admin", from: "Role"
      click_button "Update User"

      assert user.reload.admin?
    end

    should "not be able to change the role of a user who is exempt from 2SV" do
      user = create(:two_step_exempted_user)
      sign_in_as_and_edit_user(@super_admin, user)
      click_link "Change role"

      assert page.has_no_select?("Role")

      assert page.has_text? "This user's role is set to #{user.role}. They are currently exempted from 2-step verification, meaning that their role cannot be changed as admins are required to have 2-step verification."
    end
  end

  context "when logged in as an admin other than a superadmin" do
    should "not be able to change a user's role or see a warning about 2sv" do
      user = create(:two_step_exempted_user)
      sign_in_as_and_edit_user(create(:admin_user, organisation: user.organisation), user)

      assert page.has_no_select?("Role")
      assert page.has_no_text? "This user's role is set to #{user.role}. They are currently exempted from 2sv, meaning that their role cannot be changed as admins are required to have 2sv."
    end
  end
end
