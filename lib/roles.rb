module Roles
  def self.all
    [
      Roles::Admin,
      Roles::Normal,
      Roles::OrganisationAdmin,
      Roles::Superadmin,
      Roles::SuperOrganisationAdmin,
    ].sort_by(&:level)
  end

  def self.find(role_name)
    Roles.const_get(role_name.classify)
  end

  def self.names
    all.map(&:role_name)
  end

  def self.included(base)
    Roles.names.each do |role_name|
      define_method("#{role_name}?") do
        role == role_name
      end
    end
  end

  def role_class
    Roles.find(role)
  end

  def govuk_admin?
    superadmin? || admin?
  end

  def publishing_manager?
    super_organisation_admin? || organisation_admin?
  end
end
