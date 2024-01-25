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

  def self.find(role_name)
    all.find { |role| role.role_name == role_name }
  end

  def self.names
    all.map(&:role_name)
  end

  def role_class
    Roles.find(role)
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
    superadmin? || admin?
  end

  def publishing_manager?
    super_organisation_admin? || organisation_admin?
  end
end
