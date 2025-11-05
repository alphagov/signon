require "test_helper"

class AccessTokensTaskTest < ActiveSupport::TestCase
  setup do
    Signon::Application.load_tasks if Rake::Task.tasks.empty?

    @task = Rake::Task["access_tokens:renew_expiring_internal_tokens"]

    @user = create(
      :api_user,
      email: "test-app@publishing.service.gov.uk",
    )
  end

  teardown do
    @task.reenable
  end

  context "#renew_expiring_internal_tokens" do
    should "create a new token for existing tokens expiring in less than one month" do
      expiring_token = create(:access_token, expires_in: 3.weeks, resource_owner_id: @user.id)

      assert_difference "Doorkeeper::AccessToken.count", 1 do
        @task.invoke
      end

      assert_equal(expiring_token.application, Doorkeeper::AccessToken.last.application)
      assert_equal(expiring_token.resource_owner_id, Doorkeeper::AccessToken.last.resource_owner_id)
    end

    should "add an EventLog entry for the new token creation" do
      expiring_token = create(:access_token, expires_in: 2.weeks, resource_owner_id: @user.id)

      @task.invoke

      assert_equal(expiring_token.application, EventLog.last.application)
      assert_equal(EventLog::ACCESS_TOKEN_AUTO_GENERATED.id, EventLog.last.event_id)
      assert_equal(@user.uid, EventLog.last.uid)
    end

    should "not create a new token if the expiring token's user is not internal" do
      user = create(
        :api_user,
        email: "test-app@not-gds.gov.uk",
      )

      create(:access_token, expires_in: 2.weeks, resource_owner_id: user.id)

      assert_difference "Doorkeeper::AccessToken.count", 0 do
        @task.invoke
      end
    end

    should "not create a new token if a newer token already exists" do
      application = create(:application)
      _not_expiring_token = create(:access_token, expires_in: 2.months, application:, resource_owner_id: @user.id)
      _expiring_token = create(:access_token, expires_in: 3.weeks, application:, resource_owner_id: @user.id)

      assert_difference "Doorkeeper::AccessToken.count", 0 do
        @task.invoke
      end
    end
  end
end
