module Roles
  class Superadmin < Base
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

    def self.level
      0
    end

    def self.manageable_roles
      User.roles
    end
  end
end
