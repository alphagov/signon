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
      Roles.all - [Roles::Normal]
    end

    def admin_roles
      admin_role_classes.map(&:role_name)
    end

    def roles
      Roles.all.map(&:role_name)
    end
  end

  def govuk_admin?
    superadmin? || admin?
  end

  def publishing_manager?
    super_organisation_admin? || organisation_admin?
  end
end
