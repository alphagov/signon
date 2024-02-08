module Roles
  class Base
    def self.manageable_roles
      Roles.all.select { |role_class| role_class.level >= level }.reverse.map(&:role_name)
    end

    def self.can_manage?(role_name)
      manageable_roles.include?(role_name)
    end
  end
end
