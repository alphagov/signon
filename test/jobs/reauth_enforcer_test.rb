require "test_helper"

class ReauthEnforcerTest < ActiveSupport::TestCase
  context "perform" do
    should "request an app for reauthorising a user" do
      app = create(:application)
      uid = "01aac80d-0bbf-4667-9892-3b304654f3de"

      mock_client = mock("sso_push_client")
      mock_client.expects(:reauth_user).with(uid).once
      SSOPushClient.expects(:new).with(app).returns(mock_client).once

      ReauthEnforcer.new.perform(uid, app.id)
    end

    should "do nothing if the application doesn't exist" do
      SSOPushClient.any_instance.expects(:reauth_user).never

      ReauthEnforcer.new.perform("a-uid", 123)
    end
  end
end
