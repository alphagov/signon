Dir[File.dirname(__FILE__) + "/roles/*.rb"].each { |file| require file }

module Roles

  def self.included(base)
    base.extend ClassMethods

    base.instance_eval do
      validates :role, inclusion: { in: roles }

      attr_accessible *Roles::Normal.accessible_attributes
      admin_role_classes.each do |role|
        attr_accessible *role.accessible_attributes, as: role.to_s.demodulize.underscore.to_sym
      end
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

    def admin_role_classes
      role_classes - [Roles::Normal]
    end

    def roles
      role_classes.map(&:name)
    end
  end
end
