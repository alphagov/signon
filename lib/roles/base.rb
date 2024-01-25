module Roles
  class Base
    def self.manageable_roles
      Roles.all.select { |role_class| role_class.level >= level }.reverse.map(&:role_name)
    end
  end
end
