require 'test_helper'

class ReauthEnforcerTest < ActiveSupport::TestCase

  context "perform_on" do
    setup do
      ReauthEnforcer.jobs.clear
    end

    should "perform_async reauth for user's used applications" do
      user = create(:user)
      foo_app, bar_app = *create_list(:application, 2)

      # authenticate access
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: foo_app.id, token: "1234")

      ReauthEnforcer.perform_on(user)

      assert_equal 1, ReauthEnforcer.jobs.size
      assert_equal [user.uid, foo_app.id], ReauthEnforcer.jobs[0]['args']
    end

    should "perform_async reauth for applications that support push updates" do
      user = create(:user)
      yopusha = create(:application, supports_push_updates: true)
      nopusha = create(:application, supports_push_updates: false)

      # authenticate access
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: yopusha.id, token: "1234")
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: nopusha.id, token: "5678")

      ReauthEnforcer.perform_on(user)

      assert_equal 1, ReauthEnforcer.jobs.size
      assert_equal [user.uid, yopusha.id], ReauthEnforcer.jobs[0]['args']
    end
  end

  context "perform" do
    should "request an app for reauthorising a user" do
      app = create(:application)
      uid = '01aac80d-0bbf-4667-9892-3b304654f3de'

      mock_client = mock('sso_push_client')
      mock_client.expects(:reauth_user).with(uid).once
      SSOPushClient.expects(:new).with(app).returns(mock_client).once

      ReauthEnforcer.new.perform(uid, app.id)
    end
  end

end
