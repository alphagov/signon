Dir[File.dirname(__FILE__) + "/roles/*.rb"].each { |file| require file }

module Roles

  def self.included(base)
    base.extend ClassMethods

    base.instance_eval do
      validates :role, inclusion: { in: roles }

      attr_accessible *Roles::Normal.accessible_attributes
      admin_role_classes.each do |role_class|
        attr_accessible *role_class.accessible_attributes, as: role_class.to_s.demodulize.underscore.to_sym
      end
    end

  end

  def role?(base_role)
    # each role can do everything that the previous role can do
    self.class.roles.index(base_role.to_s) <= self.class.roles.index(role)
  end

  module ClassMethods
    def role_classes
      (Roles.constants.select { |c| Class === Roles.const_get(c) }).map do |role_class|
        "Roles::#{role_class}".constantize
      end
    end

    def admin_role_classes
      role_classes - [Roles::Normal]
    end

    def roles
      role_classes.map(&:role_name)
    end
  end
end
