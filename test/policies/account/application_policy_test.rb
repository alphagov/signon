require "test_helper"
require "support/policy_helpers"

class Account::ApplicationPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  context "accessing index?" do
    %i[superadmin admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = FactoryBot.build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :index)
        end
      end
    end

    %i[super_organisation_admin organisation_admin normal].each do |user_role|
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
    %i[superadmin admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :show)
        end
      end
    end

    %i[super_organisation_admin organisation_admin normal].each do |user_role|
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

  context "#grant_signin_permission?" do
    %i[superadmin admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :grant_signin_permission)
        end
      end
    end

    %i[super_organisation_admin organisation_admin normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :grant_signin_permission)
        end
      end
    end
  end

  context "#remove_signin_permission?" do
    %i[superadmin admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
          @application = build(:application)
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :remove_signin_permission)
        end
      end
    end

    %i[super_organisation_admin organisation_admin normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :remove_signin_permission)
        end
      end
    end
  end

  context "#view_permissions?" do
    %i[superadmin admin].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be permitted" do
          assert permit?(@current_user, nil, :view_permissions)
        end
      end
    end

    %i[super_organisation_admin organisation_admin normal].each do |user_role|
      context "for #{user_role} users" do
        setup do
          @current_user = build(:"#{user_role}_user")
        end

        should "be forbidden" do
          assert forbid?(@current_user, nil, :view_permissions)
        end
      end
    end
  end
end
