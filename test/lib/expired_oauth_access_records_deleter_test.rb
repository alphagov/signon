require "test_helper"

class ExpiredOauthAccessRecordsDeleterTest < ActiveSupport::TestCase
  setup do
    $stdout.stubs(:write)
  end

  context "deleting grant records" do
    should "delete expired `Doorkeeper::AccessGrant`s" do
      user = create(:user)
      create(:access_grant, resource_owner_id: user.id, expires_in: 0)
      one_hour_grant = create(:access_grant, resource_owner_id: user.id, expires_in: 1.hour)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type: :access_grant)
      deleter.delete_expired

      assert_equal [one_hour_grant], Doorkeeper::AccessGrant.where(resource_owner_id: user.id)
    end

    should "delete expired `Doorkeeper::AccessGrant`s for retired applications" do
      user = create(:user)
      grant = create(:access_grant, resource_owner_id: user.id, expires_in: 0)
      grant.application.update!(retired: true)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type: :access_grant)
      deleter.delete_expired

      assert_equal [], Doorkeeper::AccessGrant.where(resource_owner_id: user.id)
    end

    should "provide a count of the total number of records deleted" do
      user = create(:user)
      create(:access_grant, resource_owner_id: user.id, expires_in: 0)
      create(:access_grant, resource_owner_id: user.id, expires_in: 0)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type: :access_grant)
      deleter.delete_expired

      assert_equal 2, deleter.total_deleted
    end

    should "create a single account activity log entry per User" do
      user = create(:user)
      create(:access_grant, resource_owner_id: user.id, expires_in: 0)
      create(:access_grant, resource_owner_id: user.id, expires_in: 0)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type: :access_grant)
      deleter.delete_expired

      assert_equal 1, user.event_logs(event: EventLog::ACCESS_GRANTS_DELETED).count
    end
  end

  context "deleting token records" do
    should "delete expired `Doorkeeper::AccessToken`s" do
      user = create(:user)
      create(:access_token, resource_owner_id: user.id, expires_in: 0)
      one_hour_token = create(:access_token, resource_owner_id: user.id, expires_in: 1.hour)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type: :access_token)
      deleter.delete_expired

      assert_equal [one_hour_token], user.authorisations
    end

    should "delete expired `Doorkeeper::AccessToken`s for retired applications" do
      user = create(:user)
      token = create(:access_token, resource_owner_id: user.id, expires_in: 0)
      token.application.update!(retired: true)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type: :access_token)
      deleter.delete_expired

      assert_equal [], user.authorisations
    end

    should "provide a count of the total number of records deleted" do
      user = create(:user)
      create(:access_token, resource_owner_id: user.id, expires_in: 0)
      create(:access_token, resource_owner_id: user.id, expires_in: 0)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type: :access_token)
      deleter.delete_expired

      assert_equal 2, deleter.total_deleted
    end

    should "create a single account activity log entry per User" do
      user = create(:user)
      create(:access_token, resource_owner_id: user.id, expires_in: 0)
      create(:access_token, resource_owner_id: user.id, expires_in: 0)
      other_user = create(:user)
      create(:access_token, resource_owner_id: other_user.id, expires_in: 0)
      create(:access_token, resource_owner_id: other_user.id, expires_in: 0)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type: :access_token)
      deleter.delete_expired

      assert_equal(1, user.event_logs(event: EventLog::ACCESS_TOKENS_DELETED).count)
      assert_equal(1, other_user.event_logs(event: EventLog::ACCESS_TOKENS_DELETED).count)
    end

    should "include the names of the affected applications in the log entry" do
      user = create(:user)
      create(:access_token, application: create(:application, name: "Sweet Publisher"), resource_owner_id: user.id, expires_in: 0)
      create(:access_token, application: create(:application, name: "Sour Publisher"), resource_owner_id: user.id, expires_in: 0)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(record_type: :access_token)
      deleter.delete_expired

      user_event_log = user.event_logs(event: EventLog::ACCESS_TOKENS_DELETED).first
      assert_match(/Sweet/, user_event_log.trailing_message)
      assert_match(/Sour/, user_event_log.trailing_message)
    end
  end
end
