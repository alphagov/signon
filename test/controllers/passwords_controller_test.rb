require "test_helper"

class PasswordsControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = create(:user)
    @token_received_in_email = @user.__send__(:send_reset_password_instructions)
  end

  context "GET edit" do
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
end
