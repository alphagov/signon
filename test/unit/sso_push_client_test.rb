require 'test_helper'

class SSOPushClientTest < ActiveSupport::TestCase
  def reauth_url_for_app(application)
    url = URI.parse(application.redirect_uri)
    "http://#{url.host}/auth/gds/api/users/#{CGI.escape(@user.uid)}/reauth"
  end

  setup do
    @sso_push_user = create(:user, name: "SSO Push User")
    SSOPushCredential.stubs(:user_email).returns(@sso_push_user.email)

    @user = create(:user)
    @application = create(:application, redirect_uri: "http://app.com/callback")
  end

  should "send an empty POST to the app" do
    request = stub_request(:post, reauth_url_for_app(@application)).with(body: "{}")
    SSOPushClient.new(@application).reauth_user(@user.uid)
    assert_requested request
  end

  should "send the bearer token in the request" do
    SSOPushCredential.stubs(:credentials).with(@application).returns('foo')

    request = stub_request(:post, reauth_url_for_app(@application)).with(headers: { 'Authorization' => 'Bearer foo' })
    SSOPushClient.new(@application).reauth_user(@user.uid)

    assert_requested request
  end

end
