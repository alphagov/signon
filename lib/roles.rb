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

  def self.included(base)
    Roles.names.each do |role_name|
      define_method("#{role_name}?") do
        role == role_name
      end
    end
  end

  def govuk_admin?
    [Roles::Superadmin.role_name, Roles::Admin.role_name].include? role
  end

  def publishing_manager?
    [Roles::SuperOrganisationAdmin.role_name, Roles::OrganisationAdmin.role_name].include? role
  end
end
