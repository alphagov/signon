module Roles
  class Admin < Base
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
        :require_2sv,
        { supported_permission_ids: [] },
      ]
    end

    def self.role_name
      "admin"
    end

    def self.manageable_roles
      %w[normal organisation_admin super_organisation_admin admin]
    end

    def self.manageable_organisations_for(_)
      Organisation.all
    end

    def self.require_2sv?
      true
    end
  end
end
