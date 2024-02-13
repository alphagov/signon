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
    all.find { |role| role.name == role_name }
  end

  def self.names
    all.map(&:name)
  end

  all.each do |klass|
    define_method("#{klass.name}?") do
      role == klass.name
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
