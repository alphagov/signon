module Roles
  class Normal < Base
    def self.permitted_user_params
      %i[uid name email password password_confirmation]
    end

    def self.role_name
      "normal"
    end

    def self.level
      4
    end

    def self.manageable_roles
      []
    end
  end
end
