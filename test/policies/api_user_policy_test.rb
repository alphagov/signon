require "test_helper"
require "support/policy_helpers"

class ApiUserPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  %i[new create index edit update revoke manage_permissions manage_tokens suspension].each do |permission_name|
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

  %i[resend_email_change cancel_email_change].each do |permission_name|
    context permission_name do
      should "not allow" do
        assert forbid?(create(:superadmin_user), User, permission_name)
        assert forbid?(create(:admin_user), User, permission_name)
        assert forbid?(create(:super_organisation_admin_user), User, permission_name)
        assert forbid?(create(:organisation_admin_user), User, permission_name)
        assert forbid?(create(:user), User, permission_name)
      end
    end
  end
end
