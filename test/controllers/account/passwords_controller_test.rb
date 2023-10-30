require "test_helper"

class Account::PasswordsControllerTest < ActionController::TestCase
  setup do
    @original_password = "bf3b2cc3bb659ad6e740533b06c0b899"
    @user = create(:user, password: @original_password)
    sign_in @user
  end

  context "GET edit" do
    should "display form" do
      get :edit

      assert_select "form[action='#{account_password_path}']" do
        assert_select "input[type='password'][name='user[current_password]']"
        assert_select "input[type='password'][name='user[password]']"
        assert_select "input[type='password'][name='user[password_confirmation]']"
      end
    end
  end

  context "PUT update" do
    should "update password if password is sufficiently strong" do
      new_password = "0871feaffef29223358cbf086b4084c4"
      put :update, params: { user: {
        current_password: @original_password,
        password: new_password,
        password_confirmation: new_password,
      } }

      assert_redirected_to account_path
      assert @user.reload.valid_password?(new_password)
    end

    should "not update password if password is too short" do
      new_password = "short"
      put :update, params: { user: {
        current_password: @original_password,
        password: new_password,
        password_confirmation: new_password,
      } }

      assert_template :edit
      assert_select ".govuk-error-summary", text: /Password is too short/
      assert @user.reload.valid_password?(@original_password)
    end

    should "not update password if password is too weak" do
      new_password = "zymophosphate"
      put :update, params: { user: {
        current_password: @original_password,
        password: new_password,
        password_confirmation: new_password,
      } }

      assert_template :edit
      assert_select ".govuk-error-summary", text: /Password not strong enough/
      assert @user.reload.valid_password?(@original_password)
    end

    should "display validation errors" do
      put :update, params: { user: {
        current_password: "",
        password: "zymophosphate",
        password_confirmation: "doesnotmatch",
      } }

      assert_template :edit
      assert_select ".govuk-error-summary" do
        assert_select "a", href: "#user_current_password", text: "Current password can't be blank"
        assert_select "a", href: "#user_password", text: /Password not strong enough/
        assert_select "a", href: "#user_password_confirmation", text: "Password confirmation doesn't match Password"
      end
    end
  end
end
