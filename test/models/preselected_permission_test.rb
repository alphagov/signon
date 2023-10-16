require "test_helper"

class BatchInvitationTest < ActiveSupport::TestCase
  context ".permissions" do
    should "return the preselected permissions" do
      application = create(:application, name: "Asset Manager")

      assert_includes PreselectedPermission.permissions, application.signin_permission
    end

    should "not return the preselected permissions for applications that don't exist" do
      assert_empty PreselectedPermission.permissions
    end
  end
end
