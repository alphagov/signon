module Roles
  class Normal

    def self.accessible_attributes
      [:uid, :name, :email, :password, :password_confirmation]
    end

    def self.role_name
      'normal'
    end

  end
end
