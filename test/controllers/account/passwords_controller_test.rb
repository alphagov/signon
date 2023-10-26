require "test_helper"

class Account::PasswordsControllerTest < ActionController::TestCase
  def change_user_password(user_factory, new_password)
    original_password = "I am a very original password. Refrigerator weevil."
    user = create(user_factory, password: original_password)
    original_password_hash = user.encrypted_password
    sign_in user

    post :update_password,
         params: {
           user: {
             current_password: original_password,
             password: new_password,
             password_confirmation: new_password,
           },
         }

    [user, original_password_hash]
  end

  context "PUT update_password" do
    should "changing passwords to something strong should succeed" do
      user, orig_password = change_user_password(:user, "destabilizers842}orthophosphate")

      assert_redirected_to account_path

      user.reload
      assert_not_equal orig_password, user.encrypted_password
    end

    should "changing password to something too short should fail" do
      user, orig_password = change_user_password(:user, "short")

      assert_equal "200", response.code
      assert_match "too short", response.body

      user.reload
      assert_equal orig_password, user.encrypted_password
    end

    should "changing password to something too weak should fail" do
      user, orig_password = change_user_password(:user, "zymophosphate")

      assert_equal "200", response.code
      assert_match "not strong enough", response.body

      user.reload
      assert_equal orig_password, user.encrypted_password
    end
  end
end
