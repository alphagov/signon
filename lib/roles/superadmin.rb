module Roles
  class Superadmin
    def self.permitted_user_params
      [
        :uid,
        :name,
        :email,
        :password,
        :password_confirmation,
        :organisation_id,
        :unconfirmed_email,
        :confirmation_token,
        :role,
        :require_2sv,
        { supported_permission_ids: [] },
      ]
    end

    def self.role_name
      "superadmin"
    end

    def self.manageable_roles
      Roles.names
    end

    def self.can_manage?(other_role)
      manageable_roles.include?(other_role)
    end

    def self.manageable_organisations_for(_)
      Organisation.all
    end
  end
end
