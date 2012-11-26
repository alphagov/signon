require 'test_helper'

class ConfirmationsControllerTest < ActionController::TestCase

  setup do
    request.env["devise.mapping"] = Devise.mappings[:user]
    @user = FactoryGirl.create(:user_with_pending_email_change)
  end

  context "GET new" do
    should "be disabled" do
      get :new
      assert_redirected_to "/users/sign_in"
      assert_match(/Please contact support/, flash[:alert])
    end
  end

  context "POST create" do
    should "be disabled" do
      post :create, user: { email: @user.email }
      assert_redirected_to "/users/sign_in"
      assert_match(/Please contact support/, flash[:alert])
    end
  end

  context "GET show" do
    context "not signed in" do
      should "reject an invalid token" do
        get :show, confirmation_token: "fake"
        assert_match(/Please contact support/, flash[:alert])
        assert_equal false, @controller.user_signed_in?
      end

      should "not sign you in" do
        get :show, confirmation_token: @user.confirmation_token
        assert_template "devise/confirmations/show"
        assert_equal false, @controller.user_signed_in?
      end

      should "render a form" do
        get :show, confirmation_token: @user.confirmation_token
        assert_select "input#user_password"
        assert_select "input[type=hidden][name=confirmation_token][value=#{@user.confirmation_token}]"
      end
    end

    context "already signed in" do
      setup do
        sign_in @user
      end

      should "reject an invalid token" do
        get :show, confirmation_token: "fake"
        assert_match(/Please contact support/, flash[:alert])
        assert_equal @user.reload.email, "old@email.com"
      end

      should "accept the confirmation and redirect to root" do
        get :show, confirmation_token: @user.confirmation_token
        assert_redirected_to "/"
        assert_equal @user.reload.email, "new@email.com"
      end
    end

    context "signed in as somebody else" do
      setup do
        sign_in FactoryGirl.create(:user)
      end

      should "reject the attempt" do
        get :show, confirmation_token: @user.confirmation_token
        assert_redirected_to "/"
        assert_match(/It appears you followed a link meant for another user./, flash[:alert])
        assert_equal "old@email.com", @user.reload.email
      end
    end
  end

  context "PUT update" do
    should "authenticate with the correct token and password, and confirm the email change" do
      put :update, 
            confirmation_token: @user.confirmation_token, 
            user: { password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z" }
      assert_redirected_to "/"
      assert @controller.user_signed_in?
      assert_equal @user.reload.email, "new@email.com"
    end

    should "reject with an incorrect token" do
      put :update, 
            confirmation_token: "fake", 
            user: { password: "this 1s 4 v3333ry s3cur3 p4ssw0rd.!Z" }
      assert_equal false, @controller.user_signed_in?
      assert_equal @user.reload.email, "old@email.com"
    end

    should "reject with an incorrect password" do
      put :update, 
            confirmation_token: @user.confirmation_token, 
            user: { password: "not the real password" }
      assert_equal false, @controller.user_signed_in?
      assert_equal @user.reload.email, "old@email.com"
    end

    should "redisplay the form on failure" do
      put :update, 
            confirmation_token: @user.confirmation_token, 
            user: { password: "not the real password" }
      assert_template "devise/confirmations/show"
    end
  end
end
