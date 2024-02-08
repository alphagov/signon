module Roles
  class Base
    def self.manageable_roles
      Roles.all.select { |role_class| role_class.level >= level }.reverse
    end

    def self.can_manage?(role_class)
      manageable_roles.include?(role_class)
    end

    def self.display_name
      name.humanize
    end
  end
end
