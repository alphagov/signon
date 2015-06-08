require 'test_helper'

class PermissionUpdaterTest < ActiveSupport::TestCase

  def users_url(application)
    url = URI.parse(application.redirect_uri)
    "https://#{url.host}/auth/gds/api/users/#{CGI.escape(@user.uid)}"
  end

  setup do
    @sso_push_user = create(:user, name: "SSO Push User")
    SSOPushCredential.stubs(:user_email).returns(@sso_push_user.email)

    @user = create(:user)
    @application = create(:application, redirect_uri: "https://app.com/callback", with_supported_permissions: ['user_update_permission'])
    @permission = @user.grant_application_permission(@application, 'signin')
  end

  context "perform" do
    should "update the application with users information" do
      expected_body = UserOAuthPresenter.new(@user, @application).as_hash.to_json
      http_request = stub_request(:put, users_url(@application)).with(body: expected_body)

      PermissionUpdater.new.perform(@user.uid, @application.id)
      assert_requested http_request
    end

    context "successful update" do
      should "record the last_synced_at timestamp on the permission" do
        stub_request(:put, users_url(@application))

        PermissionUpdater.new.perform(@user.uid, @application.id)

        assert_not_nil @permission.reload.last_synced_at
      end
    end

    context "failed update" do
      should "not record the last_synced_at timestamp on the permission" do
        stub_request(:put, users_url(@application)).to_timeout

        PermissionUpdater.new.perform(@user.uid, @application.id) rescue SSOPushError

        assert_nil @permission.reload.last_synced_at
      end
    end

    context "handling changes in data since job was scheduled" do
      should "not attempt to update if the User doesn't exist" do
        SSOPushClient.expects(:new).never

        PermissionUpdater.new.perform(@user.uid + "foo", @application.id)
      end

      should "do nothing if the application doesn't exist" do
        SSOPushClient.expects(:new).never

        PermissionUpdater.new.perform(@user.uid, @application.id + 42)
      end

      should "not raise if the user has no permissions for the application" do
        @permission.destroy

        expected_body = UserOAuthPresenter.new(@user, @application).as_hash.to_json
        http_request = stub_request(:put, users_url(@application)).with(body: expected_body)

        PermissionUpdater.new.perform(@user.uid, @application.id)

        assert_requested http_request
      end
    end
  end
end
