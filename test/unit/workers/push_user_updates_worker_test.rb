require 'test_helper'
require 'push_user_updates_worker'

class PushUserUpdatesWorkerTest < ActiveSupport::TestCase

  class TestWorker
    include PushUserUpdatesWorker
  end

  context "perform_on" do
    setup do
      TestWorker.jobs.clear
    end

    should "perform_async updates on user's used applications" do
      user = create(:user)
      foo_app, bar_app = *create_list(:application, 2)

      # authenticate access
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: foo_app.id, token: "1234")

      TestWorker.perform_on(user)

      assert_equal 1, TestWorker.jobs.size
      assert_equal [user.uid, foo_app.id], TestWorker.jobs[0]['args']
    end

    should "perform_async updates for applications that support push updates" do
      user = create(:user)
      yopusha = create(:application, supports_push_updates: true)
      nopusha = create(:application, supports_push_updates: false)

      # authenticate access
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: yopusha.id, token: "1234")
      ::Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: nopusha.id, token: "5678")

      TestWorker.perform_on(user)

      assert_equal 1, TestWorker.jobs.size
      assert_equal [user.uid, yopusha.id], TestWorker.jobs[0]['args']
    end
  end

end
