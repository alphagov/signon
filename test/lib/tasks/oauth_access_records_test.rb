require "test_helper"

class OauthAccessRecordsTaskTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?

    @task = Rake::Task["oauth_access_records:delete_expired"]

    $stdout.stubs(:write)
  end

  teardown do
    @task.reenable # without this, calling `invoke` does nothing after first test
  end

  should "delete expired `Doorkeeper::AccessGrant`s and `Doorkeeper::AccessToken`s" do
    user = create(:user)
    create(:access_grant, resource_owner_id: user.id, expires_in: 0)
    one_hour_grant = create(:access_grant, resource_owner_id: user.id, expires_in: 1.hour)
    create(:access_token, resource_owner_id: user.id, expires_in: 0)
    one_hour_token = create(:access_token, resource_owner_id: user.id, expires_in: 1.hour)

    Timecop.travel(5.minutes.from_now)

    @task.invoke

    assert_equal [one_hour_grant], Doorkeeper::AccessGrant.where(resource_owner_id: user.id)
    assert_equal [one_hour_token], user.authorisations
  end
end
