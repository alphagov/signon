Dir[File.dirname(__FILE__) + "/roles/*.rb"].each { |file| require file }

module Roles

  def self.included(base)
    base.extend ClassMethods

    base.instance_eval do
      validates :role, inclusion: { in: roles }

      attr_accessible *Roles::Normal.accessible_attributes
      attr_accessible *Roles::Admin.accessible_attributes, as: :admin
      attr_accessible *Roles::OrganisationAdmin.accessible_attributes, as: :organisation_admin
      attr_accessible *Roles::Superadmin.accessible_attributes, as: :superadmin
    end
  end

  def role?(base_role)
    # each role can do everything that the previous role can do
    self.class.roles.index(base_role.to_s) <= self.class.roles.index(role)
  end

  module ClassMethods
    def role_classes
      (Roles.constants.select { |c| Class === Roles.const_get(c) }).map { |role| "Roles::#{role}".constantize }
    end

    def roles
      role_classes.map(&:name)
    end
  end
end
