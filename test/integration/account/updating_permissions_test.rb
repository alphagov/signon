require "test_helper"

class Account::UpdatingPermissionsTest < ActionDispatch::IntegrationTest
  # See also: UpdatingPermissionsForAppsWithManyPermissionsTest

  context "for all apps" do
    %w[superadmin admin super_organisation_admin organisation_admin].each do |role|
      context "as a #{role}" do
        should "be able to grant delegatable non-signin permissions that are grantable from the UI" do
          skip
        end
      end
    end

    %w[superadmin admin].each do |admin_role|
      context "as a #{admin_role}" do
        should "be able to grant non-delegatable permissions" do
          skip
        end
      end
    end

    %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
      context "as a #{publishing_manager_role}" do
        should "not be able to grant non-delegatable permissions" do
          skip
        end
      end
    end
  end
end
