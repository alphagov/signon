require "test_helper"

class ReauthEnforcerTest < ActiveSupport::TestCase
  context "perform" do
    should "request an app for reauthorising a user" do
      app = create(:application, supports_push_updates: true)
      uid = "01aac80d-0bbf-4667-9892-3b304654f3de"

      mock_client = mock("sso_push_client")
      mock_client.expects(:reauth_user).with(uid)
      SSOPushClient.expects(:new).with(app).returns(mock_client)

      ReauthEnforcer.new.perform(uid, app.id)
    end

    should "do nothing if the application doesn't exist" do
      SSOPushClient.any_instance.expects(:reauth_user).never

      ReauthEnforcer.new.perform("a-uid", 123)
    end

    should "do nothing if the application doesn't support push updates" do
      app = create(:application, supports_push_updates: false)

      mock_client = mock("sso_push_client")
      SSOPushClient.stubs(:new).returns(mock_client)
      mock_client.expects(:reauth_user).never

      ReauthEnforcer.new.perform("a-uid", app.id)
    end

    should "do nothing if the application is retired" do
      app = create(:application, retired: true)

      mock_client = mock("sso_push_client")
      SSOPushClient.stubs(:new).returns(mock_client)
      mock_client.expects(:reauth_user).never

      ReauthEnforcer.new.perform("a-uid", app.id)
    end
  end
end
