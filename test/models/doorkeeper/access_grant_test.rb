require "test_helper"

class Doorkeeper::AccessGrantTest < ActiveSupport::TestCase
  context ".expired" do
    should "return grants that have expired" do
      grant_expiring_1_day_ago = create(:access_grant, expires_in: -1.day)
      grant_expiring_in_1_day = create(:access_grant, expires_in: 1.day)

      grants = Doorkeeper::AccessGrant.expired

      assert_includes grants, grant_expiring_1_day_ago
      assert_not_includes grants, grant_expiring_in_1_day
    end
  end
end
