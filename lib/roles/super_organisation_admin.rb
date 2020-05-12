module Roles
  class SuperOrganisationAdmin < Base
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
        { supported_permission_ids: [] },
      ]
    end

    def self.role_name
      "super_organisation_admin"
    end

    def self.level
      2
    end

    def self.manageable_roles
      %w[normal organisation_admin super_organisation_admin]
    end
  end
end
