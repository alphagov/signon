module Roles
  class Base
    def self.can_manage?(role)
      manageable_roles.include?(role)
    end
  end
end
