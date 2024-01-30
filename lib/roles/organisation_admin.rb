module Roles
  class OrganisationAdmin < Base
    def self.permitted_user_params
      [
        :uid,
        :name,
        :email,
        :password,
        :password_confirmation,
        :unconfirmed_email,
        :confirmation_token,
        :require_2sv,
        { supported_permission_ids: [] },
      ]
    end

    def self.role_name
      "organisation_admin"
    end

    def self.level
      3
    end

    def self.manageable_organisations_for(user)
      Organisation.where(id: user.organisation)
    end
  end
end
