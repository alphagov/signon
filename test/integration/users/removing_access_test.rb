require "test_helper"

class Users::RemovingAccessTest < ActionDispatch::IntegrationTest
  context "when the signin permission is delegatable, the grantee is in the same organisation, and the granter has access" do
    %w[superadmin admin super_organisation_admin organisation_admin].each do |role|
      context "as a #{role}" do
        should("be able to remove access") { skip }
      end
    end
  end

  context "when the signin permission is not delegatable" do
    %w[superadmin admin].each do |admin_role|
      context "as a #{admin_role}" do
        should("be able to remove access") { skip }
      end
    end

    %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
      context "as a #{publishing_manager_role}" do
        should("not be able to remove access") { skip }
      end
    end
  end

  context "when the grantee is not in the same organisation" do
    %w[superadmin admin].each do |admin_role|
      context "as a #{admin_role}" do
        should("be able to remove access") { skip }
      end
    end

    context "as a super_organisation_admin" do
      should("not be able to edit the user") { skip }

      context "but the grantee's organisation is a child of the granter's" do
        should("be able to remove access") { skip }
      end
    end

    context "as a organisation_admin" do
      should("not be able to edit the user") { skip }

      context "but the grantee's organisation is a child of the granter's" do
        should("not be able to edit the user") { skip }
      end
    end
  end

  context "when the granter does not have access" do
    %w[superadmin admin].each do |admin_role|
      context "as a #{admin_role}" do
        should("be able to remove access") { skip }
      end
    end

    %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
      context "as a #{publishing_manager_role}" do
        should("not be able to remove access") { skip }
      end
    end
  end
end
