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

  def self.admin
    all - [Roles::Normal]
  end

  def self.names
    all.map(&:role_name)
  end

  def self.admin_names
    admin.map(&:role_name)
  end

  def superadmin?
    role == Roles::Superadmin.role_name
  end

  def admin?
    role == Roles::Admin.role_name
  end

  def super_organisation_admin?
    role == Roles::SuperOrganisationAdmin.role_name
  end

  def organisation_admin?
    role == Roles::OrganisationAdmin.role_name
  end

  def normal?
    role == Roles::Normal.role_name
  end

  def govuk_admin?
    [Roles::Superadmin.role_name, Roles::Admin.role_name].include? role
  end

  def publishing_manager?
    [Roles::SuperOrganisationAdmin.role_name, Roles::OrganisationAdmin.role_name].include? role
  end
end
