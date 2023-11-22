require "test_helper"
require "support/policy_helpers"

class Account::ApplicationPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "accessing index?" do
    %i[superadmin admin super_organisation_admin organisation_admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = FactoryBot.build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :index)
        end
      end
    end

    %i[normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = FactoryBot.build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :index)
        end
      end
    end
  end

  context "show?" do
    %i[superadmin admin super_organisation_admin organisation_admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :show)
        end
      end
    end

    %i[normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :show)
        end
      end
    end
  end
end
