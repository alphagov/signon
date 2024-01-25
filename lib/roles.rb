require "roles/superadmin"
require "roles/admin"
require "roles/super_organisation_admin"
require "roles/organisation_admin"
require "roles/normal"

module Roles
  def self.all
    [
      Roles::Superadmin,
      Roles::Admin,
      Roles::SuperOrganisationAdmin,
      Roles::OrganisationAdmin,
      Roles::Normal,
    ]
  end

  def self.included(base)
    base.extend ClassMethods

    base.instance_eval do
      validates :role, inclusion: { in: roles }
    end

    base.roles.each do |role_name|
      define_method("#{role_name}?") do
        role == role_name
      end
    end
  end

  module ClassMethods
    def admin_role_classes
      role_classes - [Roles::Normal]
    end

    def admin_roles
      admin_role_classes.map(&:role_name)
    end

    def roles
      Roles.all.map(&:role_name)
    end
  end

  def govuk_admin?
    [Roles::Superadmin.role_name, Roles::Admin.role_name].include? role
  end

  def publishing_manager?
    [Roles::SuperOrganisationAdmin.role_name, Roles::OrganisationAdmin.role_name].include? role
  end
end
