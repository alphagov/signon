module Roles
  class Base
    def self.manageable_roles
      Roles.all.select { |role_class| role_class.level >= level }.reverse
    end

    def self.manageable_role_names
      manageable_roles.map(&:name)
    end

    def self.can_manage?(role_name)
      manageable_role_names.include?(role_name)
    end

    def self.display_name
      name.humanize
    end
  end
end
