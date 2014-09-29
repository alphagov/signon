module Roles
  class Normal

    def self.accessible_attributes
      [:uid, :name, :email, :password, :password_confirmation]
    end

    def self.role_name
      'normal'
    end

    def self.level; 3; end

    def self.manageable_roles
      []
    end
  end
end
