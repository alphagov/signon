module Roles
  class Normal
    def self.permitted_user_params
      %i[uid name email password password_confirmation]
    end

    def self.role_name
      "normal"
    end

    def self.manageable_roles
      []
    end

    def self.can_manage?(other_role)
      manageable_roles.include?(other_role)
    end

    def self.manageable_organisations_for(_)
      Organisation.where("false")
    end
  end
end
