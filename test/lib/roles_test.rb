require "test_helper"

class RolesTest < ActiveSupport::TestCase
  class Subject
    include ActiveModel::Validations
    include Roles

    attr_accessor :role
  end

  context "Roles.all" do
    should "include all role classes" do
      expected_role_classes = [
        Roles::Normal,
        Roles::Admin,
        Roles::Superadmin,
        Roles::OrganisationAdmin,
        Roles::SuperOrganisationAdmin,
      ]

      assert_same_elements expected_role_classes, Roles.all
    end
  end

  Roles.all.each do |role| # rubocop:disable Rails/FindEach
    context "##{role.name}?" do
      setup do
        @subject = Subject.new
      end

      should "return true if subject has the #{role.name} role" do
        @subject.role = role
        assert @subject.send("#{role.name}?")
      end

      should "return false if subject does not have #{role.name} role" do
        @subject.role = Roles::Base
        assert_not @subject.send("#{role.name}?")
      end
    end
  end

  context "#govuk_admin?" do
    setup do
      @subject = Subject.new
    end

    should "be true if the role is superadmin" do
      @subject.role = Roles::Superadmin
      assert @subject.govuk_admin?
    end

    should "be true if role is admin" do
      @subject.role = Roles::Admin
      assert @subject.govuk_admin?
    end

    should "be false if role is anything else" do
      other_role_classes = Roles.all - [Roles::Superadmin, Roles::Admin]
      other_role_classes.each do |role_class|
        @subject.role = role_class
        assert_not @subject.govuk_admin?
      end
    end
  end

  context "#publishing_manager?" do
    setup do
      @subject = Subject.new
    end

    should "be true if the role is super_organisation_admin" do
      @subject.role = Roles::SuperOrganisationAdmin
      assert @subject.publishing_manager?
    end

    should "be true if role is organisation_admin" do
      @subject.role = Roles::OrganisationAdmin
      assert @subject.publishing_manager?
    end

    should "be false if role is anything else" do
      other_role_classes = Roles.all - [Roles::SuperOrganisationAdmin, Roles::OrganisationAdmin]
      other_role_classes.each do |role_class|
        @subject.role = role_class
        assert_not @subject.publishing_manager?
      end
    end
  end
end
