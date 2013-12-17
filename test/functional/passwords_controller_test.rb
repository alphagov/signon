require 'test_helper'

class PasswordsControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = create(:user)
    @user.__send__(:generate_reset_password_token!)
  end

  test "a request with a bad reset token shows an error page" do
    get :edit, reset_password_token: 'not_a_real_token'
    assert_response :success
    assert_template 'devise/passwords/reset_error'
  end

  test "a request with an expired reset token shows an error page" do
    # It'd be better to do this with a general request to the model rather
    # than editing a specific attribute, but it's not worth adding code
    # to do that for just this situation.
    @user.update_attribute(:reset_password_sent_at, 1.year.ago)

    get :edit, reset_password_token: @user.reset_password_token
    assert_response :success
    assert_template 'devise/passwords/reset_error'
  end
end