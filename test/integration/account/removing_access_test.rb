require "test_helper"

class Account::RemovingAccessTest < ActionDispatch::IntegrationTest
  context "when the signin permission is delegatable" do
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
end
