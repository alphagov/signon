require 'test_helper'

class PermissionUpdaterTest < ActiveSupport::TestCase

  def url_for_app(application)
    url = URI.parse(application.redirect_uri)
    "http://#{url.host}/auth/gds/api/users/#{CGI.escape(@user.uid)}"
  end

  setup do
    @sso_push_user = create(:user, name: "SSO Push User")
    SSOPushCredential.stubs(:user_email).returns(@sso_push_user.email)

    @user = create(:user)
    @application = create(:application, redirect_uri: "http://app.com/callback")
    @permission = create(:permission,
                                      application: @application,
                                      user: @user,
                                      permissions: ["ba"])
  end

  should "send a PUT to the related app with the user.json as in the OAuth exchange" do
    expected_body = UserOAuthPresenter.new(@user, @application).as_hash.to_json
    request = stub_request(:put, url_for_app(@application)).with(body: expected_body)
    PermissionUpdater.new(@user, @user.permissions.map(&:application)).attempt
    assert_requested request
  end

  should "return a structure of successful and failed pushes" do
    user_not_in_database = create(:application, redirect_uri: "http://user-not-in-database.com/callback")
    create(:permission,
                        application: user_not_in_database,
                        user: @user,
                        permissions: ["ba"])

    slow_app = create(:application, redirect_uri: "http://slow.com/callback")
    create(:permission,
                        application: slow_app,
                        user: @user,
                        permissions: ["ba"])

    stub_request(:put, url_for_app(@application)).to_return(status: 200)
    stub_request(:put, url_for_app(user_not_in_database)).to_return(status: 404)
    stub_request(:put, url_for_app(slow_app)).to_timeout

    results = PermissionUpdater.new(@user, @user.permissions.map(&:application)).attempt

    assert_equal [{ application: @application }], results[:successes]
    expected_failures = [
      {
        application: user_not_in_database,
        message: "SSOPushError: Error pushing to #{user_not_in_database.name} for user with uid #{@user.uid}, got response 404"
      },
      {
        application: slow_app,
        message: "SSOPushError: Error pushing to #{slow_app.name} for user with uid #{@user.uid}. Timeout connecting to application."
      }
    ]
    assert_equal expected_failures, results[:failures]
  end

  should "send the bearer token in the request" do
    SSOPushCredential.stubs(:credentials).with(@application).returns('foo')

    request = stub_request(:put, url_for_app(@application)).with(headers: { 'Authorization' => 'Bearer foo' })
    PermissionUpdater.new(@user, @user.permissions.map(&:application)).attempt

    assert_requested request
  end

  context "successful update" do
    should "record the last_synced_at timestamp on the permission" do
      expected_body = UserOAuthPresenter.new(@user, @application).as_hash.to_json

      stub_request(:put, url_for_app(@application)).with(body: expected_body)
      PermissionUpdater.new(@user, @user.permissions.map(&:application)).attempt
      assert_not_nil @permission.reload.last_synced_at
    end
  end

  context "failed update" do
    should "not record the last_synced_at timestamp on the permission" do
      expected_body = UserOAuthPresenter.new(@user, @application).as_hash.to_json

      stub_request(:put, url_for_app(@application)).to_timeout
      PermissionUpdater.new(@user, @user.permissions.map(&:application)).attempt
      assert_nil @permission.reload.last_synced_at
    end
  end
end
