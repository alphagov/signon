require "test_helper"
require "support/policy_helpers"

class SigninPermissionPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "#create?" do
    %i[superadmin admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :create)
        end
      end
    end

    %i[super_organisation_admin organisation_admin normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :create)
        end
      end
    end
  end
end
