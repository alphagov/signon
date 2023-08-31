require "test_helper"

class RolesTest < ActiveSupport::TestCase
  class Subject
    include ActiveModel::Validations
    include Roles

    attr_accessor :role
  end

  context ".role_classes" do
    should "include all role classes" do
      expected_role_classes = [
        Roles::Normal,
        Roles::Admin,
        Roles::Superadmin,
        Roles::OrganisationAdmin,
        Roles::SuperOrganisationAdmin,
      ]

      assert_same_elements expected_role_classes, Subject.role_classes
    end
  end

  context ".admin_role_classes" do
    should "only include admin role classes" do
      expected_role_classes = [
        Roles::Admin,
        Roles::Superadmin,
        Roles::OrganisationAdmin,
        Roles::SuperOrganisationAdmin,
      ]

      assert_same_elements expected_role_classes, Subject.admin_role_classes
    end
  end

  context ".roles" do
    should "order roles by their level" do
      expected_ordered_roles = %w[
        superadmin
        admin
        super_organisation_admin
        organisation_admin
        normal
      ]

      assert_equal expected_ordered_roles, Subject.roles
    end
  end

  Subject.roles.each do |role|
    context "##{role}?" do
      setup do
        @subject = Subject.new
      end

      should "return true if subject has the #{role} role" do
        @subject.role = role
        assert @subject.send("#{role}?")
      end

      should "return false if subject does not have #{role} role" do
        @subject.role = "not-#{role}"
        assert_not @subject.send("#{role}?")
      end
    end
  end
end
