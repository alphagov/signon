require "test_helper"

class SessionsControllerTest < ActionController::TestCase
  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = create(:user)
  end

  should "sign in user if credentials are valid" do
    post :create, params: { user: { email: @user.email, password: @user.password } }

    assert @controller.signed_in?
  end

  should "not sign in user if credentials are not valid" do
    post :create, params: { user: { email: @user.email, password: "incorrect-password" } }

    assert_not @controller.signed_in?
  end
end
