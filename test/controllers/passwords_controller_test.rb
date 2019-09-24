require "test_helper"

class PasswordsControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = create(:user)
    @token_received_in_email = @user.__send__(:send_reset_password_instructions)
  end

  test "GET /edit with a bad reset token shows an error page" do
    get :edit, params: { id: @user.id, reset_password_token: "not_a_real_token" }

    assert_response :success
    assert_template "devise/passwords/reset_error"
  end

  test "GET /edit with an expired reset token shows an error page" do
    @user.update_attribute(:reset_password_sent_at, 1.year.ago)

    get :edit, params: { reset_password_token: @token_received_in_email }

    assert_response :success
    assert_template "devise/passwords/reset_error"
  end
end
