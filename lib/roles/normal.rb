module Roles
  class Normal < Base
    def self.permitted_user_params
      %i[uid name email password password_confirmation]
    end

    def self.role_name
      "normal"
    end

    def self.manageable_roles
      []
    end

    def self.manageable_organisations_for(_)
      Organisation.where("false")
    end
  end
end
