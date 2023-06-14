require "test_helper"

class PushUserUpdatesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class TestJob < PushUserUpdatesJob
  end

  context "perform_on" do
    should "perform_async updates on user's used applications" do
      user = create(:user)
      foo_app, _bar_app = *create_list(:application, 2)

      # authenticate access
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: foo_app.id, token: "1234")

      assert_enqueued_with(job: TestJob, args: [user.uid, foo_app.id]) do
        TestJob.perform_on(user)
      end
    end
  end
end
