require "test_helper"

class SSOPushClientTest < ActiveSupport::TestCase
  def reauth_url(application)
    url = URI.parse(application.redirect_uri)
    "https://#{url.host}/auth/gds/api/users/#{CGI.escape(@user.uid)}/reauth"
  end

  def users_url(application)
    url = URI.parse(application.redirect_uri)
    "https://#{url.host}/auth/gds/api/users/#{CGI.escape(@user.uid)}"
  end

  context "update_user" do
    setup do
      @sso_push_user = create(:user, name: "SSO Push User")
      SSOPushCredential.stubs(:user_email).returns(@sso_push_user.email)

      @user = create(:user)
      @application = create(:application, redirect_uri: "https://app.com/callback", with_supported_permissions: %w[user_update_permission])
      @user_hash = UserOAuthPresenter.new(@user, @application).as_hash
    end

    should "send a PUT to the related app with the user.json as in the OAuth exchange" do
      request = stub_request(:put, users_url(@application)).with(body: @user_hash.to_json)
      SSOPushClient.new(@application).update_user(@user.uid, @user_hash)
      assert_requested request
    end

    should "send the bearer token in the request" do
      SSOPushCredential.stubs(:credentials).with(@application).returns("foo")

      request = stub_request(:put, users_url(@application)).with(headers: { "Authorization" => "Bearer foo" })
      SSOPushClient.new(@application).update_user(@user.uid, @user_json)

      assert_requested request
    end
  end

  context "reauth" do
    setup do
      @sso_push_user = create(:user, name: "SSO Push User")
      SSOPushCredential.stubs(:user_email).returns(@sso_push_user.email)

      @user = create(:user)
      @application = create(:application, redirect_uri: "https://app.com/callback", with_supported_permissions: %w[user_update_permission])
    end

    should "send an empty POST to the app" do
      request = stub_request(:post, reauth_url(@application)).with(body: "{}")
      SSOPushClient.new(@application).reauth_user(@user.uid)
      assert_requested request
    end

    should "send the bearer token in the request" do
      SSOPushCredential.stubs(:credentials).with(@application).returns("foo")

      request = stub_request(:post, reauth_url(@application)).with(headers: { "Authorization" => "Bearer foo" })
      SSOPushClient.new(@application).reauth_user(@user.uid)

      assert_requested request
    end
  end
end
