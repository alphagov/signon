require 'test_helper'

class PermissionUpdaterTest < ActiveSupport::TestCase

  def users_url(application)
    url = URI.parse(application.redirect_uri)
    "http://#{url.host}/auth/gds/api/users/#{CGI.escape(@user.uid)}"
  end

  setup do
    @sso_push_user = create(:user, name: "SSO Push User")
    SSOPushCredential.stubs(:user_email).returns(@sso_push_user.email)

    @user = create(:user)
    @application = create(:application, redirect_uri: "http://app.com/callback")
    @permission = create(:permission, application: @application, user: @user, permissions: ["ba"])
  end

  context "perform" do
    should "update the application with users information" do
      user_hash = UserOAuthPresenter.new(@user, @application).as_hash

      mock_client = mock('sso_push_client')
      mock_client.expects(:update_user).with(@user.uid, user_hash).once
      SSOPushClient.expects(:new).with(@application).returns(mock_client).once

      PermissionUpdater.new.perform(@user.uid, @application.id)
    end

    context "successful update" do
      should "record the last_synced_at timestamp on the permission" do
        expected_body = UserOAuthPresenter.new(@user, @application).as_hash.to_json
        stub_request(:put, users_url(@application)).with(body: expected_body)

        PermissionUpdater.new.perform(@user.uid, @application.id)

        assert_not_nil @permission.reload.last_synced_at
      end
    end

    context "failed update" do
      should "not record the last_synced_at timestamp on the permission" do
        expected_body = UserOAuthPresenter.new(@user, @application).as_hash.to_json
        stub_request(:put, users_url(@application)).to_timeout

        PermissionUpdater.new.perform(@user.uid, @application.id) rescue SSOPushError

        assert_nil @permission.reload.last_synced_at
      end
    end
  end
end
