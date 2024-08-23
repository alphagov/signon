require "test_helper"

class Account::GrantingAccessTest < ActionDispatch::IntegrationTest
  %w[superadmin admin].each do |admin_role|
    context "as a #{admin_role}" do
      should("be able to grant access") { skip }
    end
  end

  %w[super_organisation_admin organisation_admin].each do |publishing_manager_role|
    context "as a #{publishing_manager_role}" do
      should("not be able to grant access") { skip }
    end
  end
end
