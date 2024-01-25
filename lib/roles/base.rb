module Roles
  class Base
    def self.can_manage?(other_role)
      manageable_roles.include?(other_role)
    end
  end
end
