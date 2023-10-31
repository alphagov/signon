require "test_helper"

class PasswordsControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @original_password = "81de3dc67c6abddd2a52147899b45cce"
    @user = create(:user, password: @original_password)
    @token_received_in_email = @user.__send__(:send_reset_password_instructions)
  end

  context "GET edit" do
    should "show password reset form" do
      get :edit, params: { reset_password_token: @token_received_in_email }

      assert_template :edit
      assert_select "form[action='#{user_password_path}']" do
        assert_select "input[type='hidden'][name='user[reset_password_token]']"
        assert_select "input[type='password'][name='user[password]']"
        assert_select "input[type='password'][name='user[password_confirmation]']"
      end
    end

    should "show an error page if password reset token is invalid" do
      get :edit, params: { id: @user.id, reset_password_token: "not_a_real_token" }

      assert_response :success
      assert_template "devise/passwords/reset_error"
    end

    should "show an error page if password reset token has expired" do
      @user.update!(reset_password_sent_at: 1.year.ago)

      get :edit, params: { reset_password_token: @token_received_in_email }

      assert_response :success
      assert_template "devise/passwords/reset_error"
    end
  end

  context "PUT update" do
    should "update password" do
      new_password = "8320fc2efeed4b91e219a0d1974059f1"

      put :update, params: { user: {
        reset_password_token: @token_received_in_email,
        password: new_password,
        password_confirmation: new_password,
      } }

      assert_redirected_to new_user_session_path
      assert @user.reload.valid_password?(new_password)
    end

    should "not update password if password reset token is invalid" do
      new_password = "7872249c5e4ef0db04ee677c69a2f20d"

      put :update, params: { user: {
        reset_password_token: "not_a_real_token",
        password: new_password,
        password_confirmation: new_password,
      } }

      assert_template :edit
      assert_select ".govuk-error-summary" do
        assert_select "li", text: "Reset password token is invalid"
      end
      assert @user.reload.valid_password?(@original_password)
    end

    should "display validation errors" do
      put :update, params: { user: {
        reset_password_token: @token_received_in_email,
        password: "zymophosphate",
        password_confirmation: "doesnotmatch",
      } }

      assert_template :edit
      assert_select ".govuk-error-summary" do
        assert_select "li", text: /Password not strong enough/
        assert_select "li", text: "Password confirmation doesn't match Password"
      end
    end
  end
end
