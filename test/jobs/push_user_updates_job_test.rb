require "test_helper"

class PushUserUpdatesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class TestJob < PushUserUpdatesJob
  end

  context "perform_on" do
    should "perform_async updates on user's used applications" do
      user = create(:user)
      foo_app, bar_app = *create_list(:application, 2, supports_push_updates: true)

      # authenticate access
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: foo_app.id, token: "1234")

      assert_enqueued_with(job: TestJob, args: [user.uid, foo_app.id]) do
        TestJob.perform_on(user)
      end
    end

    should "perform_async updates for applications that support push updates" do
      user = create(:user)
      yopusha = create(:application, supports_push_updates: true)
      nopusha = create(:application, supports_push_updates: false)

      # authenticate access
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: yopusha.id, token: "1234")
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: nopusha.id, token: "5678")

      assert_enqueued_with(job: TestJob, args: [user.uid, yopusha.id]) do
        TestJob.perform_on(user)
      end
    end
  end
end
