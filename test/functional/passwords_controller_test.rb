require 'test_helper'

class PasswordsControllerTest < ActionController::TestCase
  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = create(:user)
    @user.__send__(:generate_reset_password_token!)
  end

  test "a request with a bad reset token shows an error page" do
    get :edit, id: @user.id, reset_password_token: 'not_a_real_token'
    assert_response :success
    assert_template 'devise/passwords/reset_error'
  end

  test "a request with an expired reset token shows an error page" do
    # It'd be better to do this with a general request to the model rather
    # than editing a specific attribute, but it's not worth adding code
    # to do that for just this situation.
    @user.update_attribute(:reset_password_sent_at, 1.year.ago)

    get :edit, id: @user.id, reset_password_token: @user.reset_password_token
    assert_response :success
    assert_template 'devise/passwords/reset_error'
  end

  test 'a partially signed-in user with an expired password trying to reset their password should get signed-out' do
    @user.update_attribute(:password_changed_at, 3.months.ago)

    # simulate a partially signed-in user. for example,
    # user with an expired password being asked to change the password
    sign_in @user
    get :edit, id: @user.id, reset_password_token: @user.reset_password_token

    assert_nil request.env['warden'].user
  end

  test 'a partially signed-in user with an expired password trying to reset their password should not be redirected to after_sign_in_path' do
    @user.update_attribute(:password_changed_at, 3.months.ago)
    sign_in @user

    get :edit, id: @user.id, reset_password_token: @user.reset_password_token

    assert_response :ok
    assert_template 'devise/passwords/edit'
  end

  test 'a partially signed-in user with an expired password should be able to request password reset instructions' do
    @user.update_attribute(:password_changed_at, 3.months.ago)

    # simulate a partially signed-in user. for example,
    # user with an expired password being asked to change the password
    sign_in @user
    get :new, forgot_expired_passphrase: 1

    assert_nil request.env['warden'].user
    assert_template 'devise/passwords/new'
  end
end
