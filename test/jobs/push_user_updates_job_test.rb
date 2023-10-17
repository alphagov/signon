require "test_helper"

class PushUserUpdatesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class TestJob < PushUserUpdatesJob
  end

  context "perform_on" do
    should "perform_async updates on user's used applications" do
      user = create(:user)
      foo_app, _bar_app = *create_list(:application, 2)

      create(:access_token, resource_owner_id: user.id, application: foo_app)

      assert_enqueued_with(job: TestJob, args: [user.uid, foo_app.id]) do
        TestJob.perform_on(user)
      end
    end

    should "not perform_async updates on user's retired applications" do
      user = create(:user)
      retired_app = create(:application, retired: true)

      create(:access_token, resource_owner_id: user.id, application: retired_app)

      assert_no_enqueued_jobs do
        TestJob.perform_on(user)
      end
    end
  end
end
