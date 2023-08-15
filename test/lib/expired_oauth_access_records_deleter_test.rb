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

      ExpiredOauthAccessRecordsDeleter.new(klass: Doorkeeper::AccessGrant).delete_expired

      assert_equal [one_hour_grant], Doorkeeper::AccessGrant.where(resource_owner_id: user.id)
    end

    should "provide a count of the total number of records deleted" do
      user = create(:user)
      create(:access_grant, resource_owner_id: user.id, expires_in: 0)
      create(:access_grant, resource_owner_id: user.id, expires_in: 0)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(klass: Doorkeeper::AccessGrant)
      deleter.delete_expired

      assert_equal 2, deleter.total_deleted
    end
  end

  context "deleting token records" do
    should "delete expired `Doorkeeper::AccessToken`s" do
      user = create(:user)
      create(:access_token, resource_owner_id: user.id, expires_in: 0)
      one_hour_token = create(:access_token, resource_owner_id: user.id, expires_in: 1.hour)

      Timecop.travel(5.minutes.from_now)

      ExpiredOauthAccessRecordsDeleter.new(klass: Doorkeeper::AccessToken).delete_expired

      assert_equal [one_hour_token], user.authorisations
    end

    should "provide a count of the total number of records deleted" do
      user = create(:user)
      create(:access_token, resource_owner_id: user.id, expires_in: 0)
      create(:access_token, resource_owner_id: user.id, expires_in: 0)

      Timecop.travel(5.minutes.from_now)

      deleter = ExpiredOauthAccessRecordsDeleter.new(klass: Doorkeeper::AccessToken)
      deleter.delete_expired

      assert_equal 2, deleter.total_deleted
    end
  end
end
