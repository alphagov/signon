module Roles
  class Base
    def self.manageable_roles
      User.role_classes.select { |role_class| role_class.level >= level }.sort_by(&:level).reverse.map(&:role_name)
    end
  end
end
