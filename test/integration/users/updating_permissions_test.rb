require "test_helper"

class Users::UpdatingPermissionsTest < ActionDispatch::IntegrationTest
  # See also: UpdatingPermissionsForAppsWithManyPermissionsTest

  context "for all apps" do
    context "when the grantee is in the same organisation, and the granter has access" do
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

    context "when the grantee is not in the same organisation" do
      %w[superadmin admin].each do |admin_role|
        context "as a #{admin_role}" do
          should "be able to grant permissions" do
            skip
          end
        end
      end

      context "as a super_organisation_admin" do
        should("not be able to edit the user") { skip }

        context "but the grantee's organisation is a child of the granter's" do
          should "be able to grant permissions" do
            skip
          end
        end
      end

      context "as a super_organisation_admin" do
        should("not be able to edit the user") { skip }

        context "but the grantee's organisation is a child of the granter's" do
          should("not be able to edit the user") { skip }
        end
      end
    end

    context "when the granter does not have permissions" do
      %w[superadmin admin].each do |admin_role|
        context "as a #{admin_role}" do
          should "be able to grant permissions" do
            skip
          end
        end
      end

      %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
        context "as a #{publishing_manager_role}" do
          should "not be able to grant any permissions for the app" do
            skip
          end
        end
      end
    end
  end
end
