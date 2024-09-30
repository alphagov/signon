require "test_helper"
require "support/policy_helpers"

class BatchInvitationPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "new" do
    should "allow superadmins and admins to create new batch uploads" do
      assert permit?(create(:superadmin_user), BatchInvitation.new, :new)
      assert permit?(create(:admin_user), BatchInvitation.new, :new)
    end

    should "forbid organisation admins to create new batch uploads even within their organisation subtree" do
      organisation_admin = create(:organisation_admin_user)

      assert forbid?(organisation_admin, BatchInvitation.new, :new)
      assert forbid?(organisation_admin, BatchInvitation.new(organisation_id: create(:organisation).id), :new)
      assert forbid?(organisation_admin, BatchInvitation.new(organisation_id: organisation_admin.organisation_id), :new)
    end

    should "forbid for normal users" do
      assert forbid?(create(:user), BatchInvitation.new, :new)
    end
  end
end
