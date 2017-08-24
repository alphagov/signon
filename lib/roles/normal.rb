module Roles
  class Normal < Base
    def self.permitted_user_params
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
