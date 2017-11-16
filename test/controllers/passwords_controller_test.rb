require 'test_helper'

class PasswordsControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = create(:user)
    @token_received_in_email = @user.__send__(:send_reset_password_instructions)
  end

  test "GET /edit with a bad reset token shows an error page" do
    get :edit, params: { id: @user.id, reset_password_token: 'not_a_real_token' }

    assert_response :success
    assert_template 'devise/passwords/reset_error'
  end

  test "GET /edit with an expired reset token shows an error page" do
    @user.update_attribute(:reset_password_sent_at, 1.year.ago)

    get :edit, params: { reset_password_token: @token_received_in_email }

    assert_response :success
    assert_template 'devise/passwords/reset_error'
  end

  test 'GET /edit by a partially signed-in user with an expired password trying to reset their password should gets signed-out' do
    @user.update_attribute(:password_changed_at, 91.days.ago)

    # simulate a partially signed-in user. for example,
    # user with an expired password being asked to change the password
    sign_in @user
    get :edit, params: { id: @user.id, reset_password_token: @token_received_in_email }

    assert_nil request.env['warden'].user
  end

  test 'GET /edit by partially signed-in user with an expired password trying to reset their password should not be redirected to after_sign_in_path' do
    @user.update_attribute(:password_changed_at, 91.days.ago)
    sign_in @user

    get :edit, params: { id: @user.id, reset_password_token: @token_received_in_email }

    assert_response :ok
    assert_template 'devise/passwords/edit'
  end

  test 'GET /new by partially signed-in user with an expired password should be able to request password reset instructions' do
    @user.update_attribute(:password_changed_at, 91.days.ago)

    # simulate a partially signed-in user. for example,
    # user with an expired password being asked to change the password
    sign_in @user
    get :new, params: { forgot_expired_passphrase: 1 }

    assert_nil request.env['warden'].user
    assert_template 'devise/passwords/new'
  end
end
