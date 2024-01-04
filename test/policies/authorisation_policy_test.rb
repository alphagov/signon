require "test_helper"
require "support/policy_helpers"

class AuthorisationPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  %i[new create edit revoke].each do |permission_name|
    context permission_name do
      should "allow only for superadmins" do
        assert permit?(create(:superadmin_user), User, permission_name)

        assert forbid?(create(:admin_user), User, permission_name)
        assert forbid?(create(:super_organisation_admin_user), User, permission_name)
        assert forbid?(create(:organisation_admin_user), User, permission_name)
        assert forbid?(create(:user), User, permission_name)
      end
    end
  end
end
