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

  all.each do |role_class|
    define_method("#{role_class.role_name}?") do
      role == role_class
    end
  end

  def govuk_admin?
    superadmin? || admin?
  end

  def publishing_manager?
    super_organisation_admin? || organisation_admin?
  end
end
