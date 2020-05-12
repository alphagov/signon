module Roles
  class OrganisationAdmin < Base
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
      "organisation_admin"
    end

    def self.level
      3
    end

    def self.manageable_roles
      %w[normal organisation_admin]
    end
  end
end
